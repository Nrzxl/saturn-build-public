import 'streaming_preferences.dart';

/// Somente URLs de PÁGINAS DE TÍTULO dentro dos serviços oficiais.
/// Não transforma uma busca em um link "Assistir".
///
/// URLs descobertas em metadados oficiais e links colados pelo usuário passam
/// pelo mesmo filtro; a existência de um link não prova licenciamento no Brasil.
String? checkedTitleUrl(StreamingService service, String? input) {
  if (input == null || input.trim().isEmpty) return null;
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.host.isEmpty) {
    return null;
  }

  final host = uri.host.toLowerCase();
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final safeHost = host.startsWith('www.') ? host.substring(4) : host;
  bool accepted = false;

  switch (service) {
    case StreamingService.netflix:
      accepted = safeHost == 'netflix.com' &&
          parts.length >= 2 &&
          (parts[0] == 'title' || parts[0] == 'watch') &&
          RegExp(r'^\d{4,}$').hasMatch(parts[1]);
    case StreamingService.crunchyroll:
      final first = parts[0].toLowerCase();
      final localised = RegExp(r'^[a-z]{2}(?:-[a-z]{2})?$').hasMatch(first);
      final index = localised ? 1 : 0;
      accepted = safeHost == 'crunchyroll.com' &&
          parts.length > index + 1 &&
          (parts[index] == 'series' || parts[index] == 'watch') &&
          parts[index + 1].isNotEmpty;
    case StreamingService.primeVideo:
      if (safeHost == 'primevideo.com') {
        accepted = parts.length >= 2 && parts[0] == 'detail' &&
            parts[1].isNotEmpty;
      } else if (safeHost == 'amazon.com' || safeHost == 'amazon.com.br') {
        final video = parts.indexOf('video');
        accepted = video >= 0 && video + 2 < parts.length &&
            parts[video + 1] == 'detail' &&
            parts[video + 2].isNotEmpty;
      }
  }
  if (!accepted) return null;

  // Remove parâmetros de campanha e fragmentos desnecessários.
  return Uri(scheme: 'https', host: uri.host, path: uri.path).toString();
}

/// Extrai apenas URLs oficiais e específicas de uma obra do campo
/// AniList Media.externalLinks. A AniList não certifica oferta no Brasil.
Map<String, String> extractOfficialTitleLinks(Object? externalLinks) {
  final links = <String, String>{};
  if (externalLinks is! List) return links;
  for (final candidate in externalLinks) {
    if (candidate is! Map) continue;
    final address = candidate['url'];
    if (address is! String) continue;
    for (final service in StreamingService.values) {
      final validated = checkedTitleUrl(service, address);
      if (validated != null) {
        links.putIfAbsent(service.name, () => validated);
      }
    }
  }
  return links;
}

Uri officialSearchUri(StreamingService service, String title) {
  final query = title.trim();
  switch (service) {
    case StreamingService.netflix:
      return Uri.https('www.netflix.com', '/search', {'q': query});
    case StreamingService.crunchyroll:
      return Uri.https('www.crunchyroll.com', '/search', {'q': query});
    case StreamingService.primeVideo:
      return Uri.https('www.primevideo.com', '/search', {'phrase': query});
  }
}
