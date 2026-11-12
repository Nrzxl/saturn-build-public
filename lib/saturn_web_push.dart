import 'dart:convert';

import 'saturn_orbit_cloud.dart';
import 'saturn_push_browser_stub.dart'
    if (dart.library.js_interop) 'saturn_push_browser_web.dart' as browser;

/// Server-signed Web Push. VAPID private key lives only in Supabase.
/// All requests use the user's own JWT and verified Orbit membership.
class SaturnWebPush {
  const SaturnWebPush._();

  static String get support => browser.SaturnBrowserPush.support();

  static Future<void> enable(SaturnOrbitCloud cloud) async {
    if (!cloud.connected || cloud.orbitId == null) {
      throw StateError('Conecte a Nossa Órbita para receber notificações.');
    }
    // MUST be the first asynchronous operation in a direct tap callback.
    final permission = await browser.SaturnBrowserPush.permission();
    if (permission != 'granted') {
      throw StateError(permission == 'install'
          ? 'No iPhone, adicione SATURN à Tela de Início antes de ativar.'
          : permission == 'denied'
          ? 'Permita notificações nas configurações do seu navegador.'
          : 'Este navegador ainda não oferece Web Push.');
    }
    final result = await cloud.client.functions.invoke('saturn-push',
        body: {'action': 'public_key', 'orbitId': cloud.orbitId});
    final data = result.data;
    if (data is! Map || data['publicKey'] is! String) {
      throw StateError('Servidor de notificações indisponível.');
    }
    final raw = await browser.SaturnBrowserPush.subscribe(
        data['publicKey'] as String);
    final sub = jsonDecode(raw);
    if (sub is! Map) throw StateError('Assinatura inválida.');
    await cloud.client.functions.invoke('saturn-push',
        body: {'action': 'subscribe', 'orbitId': cloud.orbitId,
          'subscription': sub});
  }

  static Future<void> disable(SaturnOrbitCloud cloud) async {
    if (!cloud.connected || cloud.orbitId == null) {
      throw StateError('Conecte a Nossa Órbita para desativar o Push.');
    }
    final endpoint = await browser.SaturnBrowserPush.unsubscribe();
    if (endpoint.isEmpty) return;
    await cloud.client.functions.invoke('saturn-push', body: {
      'action': 'unsubscribe', 'orbitId': cloud.orbitId,
      'endpoint': endpoint,
    });
  }

  static Future<void> dispatch(
    SaturnOrbitCloud? cloud, {
    required String kind, required String workId,
    required int at, String key = '',
  }) async {
    if (cloud == null || !cloud.connected || cloud.orbitId == null) return;
    // Cloud may already be syncing a simultaneous edit from the partner.
    // Wait and retry validation rather than losing a notification to a
    // temporary stale revision or a just-created series record.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await cloud.syncNow();
        await cloud.client.functions.invoke('saturn-push', body: {
          'action': 'dispatch', 'orbitId': cloud.orbitId,
          'kind': kind, 'workId': workId, 'key': key, 'at': at,
        });
        return;
      } catch (_) {
        if (attempt == 2) return;
        await Future<void>.delayed(
          Duration(milliseconds: 900 * (attempt + 1)));
      }
    }
  }
}
