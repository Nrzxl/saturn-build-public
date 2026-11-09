import 'dart:convert';

import 'package:http/http.dart' as http;

/// Canal público separado do código privado. A publicação ainda depende
/// de criar Nrzxl/saturn-downloads e configurar assinatura persistente.
const saturnUpdateFeed =
    'https://raw.githubusercontent.com/Nrzxl/saturn-downloads/main/update.json';
const saturnBuildsPage =
    'https://github.com/Nrzxl/saturn-mobile/actions/workflows/build.yml';

enum UpdateState { available, current, notConfigured, failed }

class SaturnRelease {
  final String version;
  final int build;
  final String apkUrl;
  final String sha256;
  final String notes;

  const SaturnRelease({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.sha256,
    required this.notes,
  });

  factory SaturnRelease.parse(Object? value) {
    if (value is! Map) {
      throw const FormatException('Manifesto de atualização inválido.');
    }
    final version = value['version'];
    final build = value['build'];
    final apkUrl = value['apk_url'];
    final sha256 = value['sha256'];
    final notes = value['notes'] ?? '';
    if (version is! String ||
        version.trim().isEmpty ||
        build is! int ||
        build < 1 ||
        apkUrl is! String ||
        sha256 is! String ||
        notes is! String) {
      throw const FormatException('Manifesto incompleto.');
    }
    final uri = Uri.tryParse(apkUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        uri.userInfo.isNotEmpty ||
        !uri.path.startsWith('/Nrzxl/saturn-downloads/releases/download/') ||
        !uri.path.endsWith('.apk') ||
        uri.pathSegments.length < 6 ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException('Origem de atualização não autorizada.');
    }
    return SaturnRelease(
      version: version,
      build: build,
      apkUrl: apkUrl,
      sha256: sha256.toLowerCase(),
      notes: notes,
    );
  }
}

class UpdateCheckResult {
  final UpdateState state;
  final String message;
  final SaturnRelease? release;
  const UpdateCheckResult(this.state, this.message, [this.release]);
}

/// Consulta apenas o manifesto. A instalação automática e a verificação
/// dos bytes do APK por SHA-256 NÃO estão implementadas nesta etapa.
class SaturnUpdateService {
  final http.Client _client;
  final Uri _feed;

  SaturnUpdateService({
    http.Client? client,
    Uri? feed,
  })  : _client = client ?? http.Client(),
        _feed = feed ?? Uri.parse(saturnUpdateFeed);

  void dispose() => _client.close();

  Future<UpdateCheckResult> check({required int currentBuild}) async {
    try {
      final response = await _client.get(
        _feed,
        headers: const {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) {
        return const UpdateCheckResult(
          UpdateState.notConfigured,
          'O canal de atualizações ainda não foi publicado. '
          'Você pode conferir os APKs de teste pelo GitHub Actions.',
        );
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          UpdateState.failed,
          'Não foi possível consultar as versões (HTTP ${response.statusCode}).',
        );
      }
      final release = SaturnRelease.parse(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
      if (release.build > currentBuild) {
        return UpdateCheckResult(
          UpdateState.available,
          'SATURN ${release.version} disponível.',
          release,
        );
      }
      return UpdateCheckResult(
        UpdateState.current,
        'Seu SATURN já está na versão mais recente do canal de distribuição.',
        release,
      );
    } on FormatException {
      return const UpdateCheckResult(
        UpdateState.failed,
        'O canal respondeu com informações inválidas; nenhuma atualização foi oferecida.',
      );
    } catch (_) {
      return const UpdateCheckResult(
        UpdateState.failed,
        'Sem acesso ao canal de atualização. Confira a internet e tente novamente.',
      );
    }
  }
}
