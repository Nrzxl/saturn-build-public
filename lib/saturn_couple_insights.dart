
/** Read-only couple insights derived from existing SATURN records.

 No new persistence keys, fake shared progress, or external services.
 Each person keeps independent notes, ratings and statuses.
*/
class SaturnCoupleInsights {
  SaturnCoupleInsights(Iterable<String> sharedIds, this.records)
      : ids = List<String>.unmodifiable(sharedIds.toSet());

  final List<String> ids;
  final Map<String, dynamic> records;

  Map<String, dynamic> profile(int person, String workId) {
    final raw = records['$person:$workId'];
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  bool finished(int person, String workId) {
    final value = profile(person, workId)['status'];
    return value == 'Concluído' || value == 'Assistido' || value == 'Lido';
  }

  bool get hasStories => ids.isNotEmpty;

  bool finishedTogether(String workId) =>
      finished(0, workId) && finished(1, workId);

  bool isInProgress(String workId) =>
      !finishedTogether(workId) &&
      (profile(0, workId)['status'] == 'Em andamento' ||
       profile(1, workId)['status'] == 'Em andamento');

  bool hasMemory(String workId) =>
      [0, 1].any((person) =>
          (profile(person, workId)['notes'] ?? '').toString().trim().isNotEmpty);

  bool bothRated(String workId) =>
      [0, 1].every((person) =>
          profile(person, workId)['rating'] is num &&
          (profile(person, workId)['rating'] as num) > 0);

  int get completedTogether =>
      ids.where(finishedTogether).length;

  int get inProgress =>
      ids.where(isInProgress).length;

  int get memories =>
      ids.where(hasMemory).length;

  int get reviewsFromBoth =>
      ids.where(bothRated).length;

  bool matches(String workId, String view) {
    switch (view) {
      case 'Para descobrir':
        return !finishedTogether(workId) && !isInProgress(workId);
      case 'Em andamento':
        return isInProgress(workId);
      case 'Vividas por nós':
        return finishedTogether(workId);
      default:
        return true;
    }
  }

  String profileStatus(int person, String workId, {bool book = false}) {
    if (finished(person, workId)) return book ? 'Lido' : 'Assistido';
    final status = profile(person, workId)['status']?.toString().trim() ?? '';
    return status.isEmpty ? 'Ainda sem registro' : status;
  }
}
