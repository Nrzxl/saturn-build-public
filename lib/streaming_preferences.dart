/// Serviços favoritos para atalhos de pesquisa. Não prova disponibilidade.
enum StreamingService {
  netflix('Netflix', 'netflix.com', 'https://www.netflix.com/search'),
  crunchyroll('Crunchyroll', 'crunchyroll.com', 'https://www.crunchyroll.com/search'),
  primeVideo('Prime Video', 'primevideo.com', 'https://www.primevideo.com/search');

  const StreamingService(this.label, this.domain, this.searchPage);
  final String label;
  final String domain;
  final String searchPage;

  Uri get uri => Uri.parse(searchPage);
}

const defaultStreamingServices = <StreamingService>{
  StreamingService.netflix,
  StreamingService.crunchyroll,
  StreamingService.primeVideo,
};

Set<StreamingService> decodeStreamingPreferences(Object? raw) {
  if (raw is! List) return {...defaultStreamingServices};
  return StreamingService.values
      .where((service) => raw.contains(service.name))
      .toSet();
}

List<String> encodeStreamingPreferences(Set<StreamingService> selected) =>
    StreamingService.values
        .where(selected.contains)
        .map((service) => service.name)
        .toList();
