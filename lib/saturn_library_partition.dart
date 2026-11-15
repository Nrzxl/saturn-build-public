/// Visual-only split of the personal SATURN library. A work is never moved,
/// deleted or copied in local storage or Supabase when switching tabs.
///
/// "Explorar" continues to search all media kinds; "Nossa Órbita" also keeps
/// its own existing filters and shared book records.
class SaturnLibraryPartition {
  const SaturnLibraryPartition._();

  static bool isBook(String kind) => kind == 'Livro';

  static List<T> books<T>(
    Iterable<T> works,
    String Function(T work) kind,
  ) => works.where((work) => isBook(kind(work)))
      .toList(growable: false);

  static List<T> collection<T>(
    Iterable<T> works,
    String Function(T work) kind,
  ) => works.where((work) => !isBook(kind(work)))
      .toList(growable: false);
}
