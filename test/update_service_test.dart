import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saturn_app/update_service.dart';
import 'package:saturn_app/streaming_preferences.dart';

const _fakeSha =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _trustedApk =
    'https://github.com/Nrzxl/saturn-downloads/releases/download/v0.2.1/SATURN.apk';

void main() {
  test('Netflix, Crunchyroll e Prime Video iniciam selecionados', () {
    final parsed = decodeStreamingPreferences(null);
    expect(parsed, containsAll(StreamingService.values));
    expect(encodeStreamingPreferences({
      StreamingService.netflix,
      StreamingService.crunchyroll,
    }), ['netflix', 'crunchyroll']);
  });

  test('Salvamento vazio respeita usuário sem nenhuma plataforma', () {
    expect(decodeStreamingPreferences([]), isEmpty);
    expect(decodeStreamingPreferences(['netflix', 'desconhecida']),
        {StreamingService.netflix});
    expect(StreamingService.primeVideo.uri.host, 'www.primevideo.com');
  });

  test('Manifesto aceita somente URL de release SATURN autorizada', () {
    final valid = SaturnRelease.parse({
      'version': '0.2.1',
      'build': 6,
      'apk_url': _trustedApk,
      'sha256': _fakeSha,
      'notes': 'Novidades',
    });
    expect(valid.build, 6);
    expect(valid.apkUrl, _trustedApk);
    expect(
      () => SaturnRelease.parse({
        'version': '0.2.1',
        'build': 6,
        'apk_url': 'https://evil.example/SATURN.apk',
        'sha256': _fakeSha,
        'notes': '',
      }),
      throwsFormatException,
    );
    expect(
      () => SaturnRelease.parse({
        'version': '0.2.1',
        'build': 6,
        'apk_url': _trustedApk,
        'sha256': 'wrong',
        'notes': '',
      }),
      throwsFormatException,
    );
  });

  test('404 indica canal ainda não configurado', () async {
    final service = SaturnUpdateService(
      client: MockClient((request) async {
        expect(request.url.host, 'raw.githubusercontent.com');
        return http.Response('Not found', 404);
      }),
    );
    addTearDown(service.dispose);
    final result = await service.check(currentBuild: 4);
    expect(result.state, UpdateState.notConfigured);
  });

  test('Identifica atualização quando build remoto é maior', () async {
    final service = SaturnUpdateService(
      client: MockClient((request) async => http.Response(
        jsonEncode({
          'version': '0.2.2',
          'build': 7,
          'apk_url': _trustedApk,
          'sha256': _fakeSha,
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      )),
    );
    addTearDown(service.dispose);
    final available = await service.check(currentBuild: 4);
    expect(available.state, UpdateState.available);
    expect(available.release?.build, 7);
    final current = await service.check(currentBuild: 7);
    expect(current.state, UpdateState.current);
  });

  test('Feed com origem maliciosa é recusado', () async {
    final service = SaturnUpdateService(
      client: MockClient((request) async => http.Response(
        jsonEncode({
          'version': '99',
          'build': 999,
          'apk_url': 'https://github.com/attacker/fake/releases/download/v1/app.apk',
          'sha256': _fakeSha,
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      )),
    );
    addTearDown(service.dispose);
    final result = await service.check(currentBuild: 4);
    expect(result.state, UpdateState.failed);
  });
}
