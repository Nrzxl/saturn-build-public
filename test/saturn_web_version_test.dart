import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_web_version.dart';

const installed = '0123456789abcdef0123456789abcdef01234567';
const published = '89abcdef0123456789abcdef0123456789abcdef';

void main() {
  test('PWA identifica que a publicação está atual', () {
    expect(
      compareSaturnWebBuild(
        installedSha: installed,
        publishedResponse: ' $installed\n',
      ),
      SaturnWebBuildState.current,
    );
  });

  test('PWA detecta novo commit sem tocar no armazenamento', () {
    expect(
      compareSaturnWebBuild(
        installedSha: installed,
        publishedResponse: published,
      ),
      SaturnWebBuildState.available,
    );
  });

  test('PWA antigo sem SHA recebe orientação de atualização', () {
    expect(
      compareSaturnWebBuild(
        installedSha: '',
        publishedResponse: published,
      ),
      SaturnWebBuildState.unknownLocal,
    );
  });

  test('PWA rejeita conteúdo inesperado ou erro HTML no manifesto', () {
    for (final response in [
      '<html>404</html>', 'not-a-commit', '../index.html',
      'A' * 40, '',
    ]) {
      expect(
        () => compareSaturnWebBuild(
          installedSha: installed,
          publishedResponse: response,
        ),
        throwsFormatException,
      );
    }
  });
}
