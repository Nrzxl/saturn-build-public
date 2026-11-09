/// Browser deployment versions are the 40-character Git commit SHAs written
/// by GitHub Pages to saturn-build.txt during a successful build.
enum SaturnWebBuildState { current, available, unknownLocal }

final RegExp _shaPattern = RegExp(r'^[a-f0-9]{40}$');

SaturnWebBuildState compareSaturnWebBuild({
  required String installedSha,
  required String publishedResponse,
}) {
  final publishedSha = publishedResponse.trim();
  if (!_shaPattern.hasMatch(publishedSha)) {
    throw const FormatException('Resposta de versão Web inválida');
  }
  if (!_shaPattern.hasMatch(installedSha)) {
    // A previous Web release may predate the embedded SHA.
    return SaturnWebBuildState.unknownLocal;
  }
  return installedSha == publishedSha
      ? SaturnWebBuildState.current
      : SaturnWebBuildState.available;
}
