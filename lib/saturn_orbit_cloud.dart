import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'saturn_orbit_merge.dart';

/// Values set at build time through --dart-define. The publishable key is
/// public by design; NEVER use a Supabase service_role or secret API key.
class SaturnCloudConfig {
  static const url = String.fromEnvironment('SATURN_SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
      'SATURN_SUPABASE_PUBLISHABLE_KEY');

  static bool get enabled =>
      url.startsWith('https://') &&
      Uri.tryParse(url)?.host.endsWith('.supabase.co') == true &&
      publishableKey.isNotEmpty;
}

typedef ReadOrbitState = Map<String, dynamic> Function();
typedef ApplyOrbitState = Future<void> Function(Map<String, dynamic> merged);

/// All cloud operations are opt-in and operate exclusively on a dedicated
/// SATURN RLS project, never on CDI production databases.
class SaturnOrbitCloud {
  SaturnOrbitCloud({
    required this.readLocal,
    required this.apply,
    required this.onStatus,
  });

  final ReadOrbitState readLocal;
  final ApplyOrbitState apply;
  final void Function() onStatus;
  SupabaseClient get client => Supabase.instance.client;

  String? orbitId;
  String? lastError;
  DateTime? lastSyncedAt;
  bool busy = false;
  bool _pending = false;
  Timer? _debounce;
  StreamSubscription<dynamic>? _changes;

  String? get userId => client.auth.currentUser?.id;
  bool get signedIn => userId != null;
  bool get connected => signedIn && orbitId != null;

  Future<void> sendEmailCode(String email) async {
    await client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true);
  }

  Future<void> verifyEmailCode(String email, String code) async {
    await client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    onStatus();
  }

  Future<List<String>> availableOrbits() async {
    final uid = userId;
    if (uid == null) return [];
    final rows = await client
        .from('saturn_orbit_members')
        .select('orbit_id')
        .eq('user_id', uid);
    return [
      for (final row in rows)
        if (row['orbit_id'] is String) row['orbit_id'] as String,
    ];
  }

  Future<String> createOrbit() async {
    final uid = userId;
    if (uid == null) throw StateError('Entre com seu e-mail primeiro.');
    final orbit = await client.from('saturn_orbits').insert({
      'owner_id': uid,
      'title': 'Nossa Órbita',
    }).select('id').single();
    final id = orbit['id'].toString();
    await client.from('saturn_orbit_members').insert({
      'orbit_id': id,
      'user_id': uid,
    });
    await client.from('saturn_orbit_state').insert({
      'orbit_id': id,
      'document': {'schema': 1},
      'revision': 0,
    });
    await attach(id);
    return id;
  }

  /// Explicit owner approval: partner shares their own Auth UUID. No
  /// short, guessable invitation secret or authentication bypass.
  Future<void> addPartner(String partnerId) async {
    if (orbitId == null) throw StateError('Escolha uma Órbita primeiro.');
    final code = partnerId.trim();
    if (!RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')
        .hasMatch(code)) {
      throw FormatException('O código do outro perfil não é válido.');
    }
    final current = await client.from('saturn_orbit_members')
        .select('user_id')
        .eq('orbit_id', orbitId!)
        .eq('user_id', code);
    if (current.isNotEmpty) return;
    await client.from('saturn_orbit_members').insert({
      'orbit_id': orbitId,
      'user_id': code,
    });
  }

  Future<void> attach(String nextOrbitId) async {
    // Verify membership through RLS before subscribing.
    final uid = userId;
    if (uid == null) throw StateError('Entre com seu e-mail.');
    final rows = await client.from('saturn_orbit_members')
        .select('orbit_id')
        .eq('orbit_id', nextOrbitId)
        .eq('user_id', uid);
    if (rows.isEmpty) throw StateError('Acesso à Órbita não autorizado.');
    await _changes?.cancel();
    orbitId = nextOrbitId;
    _changes = client
        .from('saturn_orbit_state')
        .stream(primaryKey: ['orbit_id'])
        .eq('orbit_id', nextOrbitId)
        .listen(
          (_) => scheduleSync(),
          onError: (Object e) {
            lastError = 'Sincronização em tempo real indisponível.';
            onStatus();
          },
        );
    onStatus();
    await syncNow();
  }

  void scheduleSync() {
    if (!connected) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), syncNow);
  }

  Future<void> syncNow() async {
    if (!connected) return;
    if (busy) {
      _pending = true;
      return;
    }
    busy = true;
    lastError = null;
    onStatus();
    try {
      final id = orbitId!;
      for (var attempt = 0; attempt < 5; attempt++) {
        final remote = await client
            .from('saturn_orbit_state')
            .select('revision,document')
            .eq('orbit_id', id)
            .maybeSingle();
        if (remote == null) {
          throw StateError('Órbita ainda não tem documento inicial.');
        }
        final revision = (remote['revision'] as num).toInt();
        final raw = remote['document'];
        final cloud = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final merged = SaturnOrbitMerge.merge(readLocal(), cloud);
        final same = SaturnOrbitMerge.canonical(merged) ==
            SaturnOrbitMerge.canonical(cloud);
        if (!same) {
          final updated = await client
              .from('saturn_orbit_state')
              .update({
                'document': merged,
                'revision': revision + 1,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('orbit_id', id)
              .eq('revision', revision)
              .select('revision');
          if (updated.isEmpty) {
            // Concurrent update; fetch again and merge both changes.
            continue;
          }
        }
        await apply(merged);
        lastSyncedAt = DateTime.now();
        onStatus();
        return;
      }
      throw StateError('Outra edição ocorreu; tente novamente.');
    } catch (_) {
      // Never destroy or reset the local library when offline or unauthorized.
      lastError = 'Sem sincronizar. Dados mantidos neste aparelho.';
      onStatus();
    } finally {
      busy = false;
      if (_pending) {
        _pending = false;
        scheduleSync();
      }
      onStatus();
    }
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    await _changes?.cancel();
    _changes = null;
    orbitId = null;
    await client.auth.signOut();
    onStatus();
  }

  void dispose() {
    _debounce?.cancel();
    _changes?.cancel();
  }
}
