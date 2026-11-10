/// Read-only and deliberately time-gated annual highlights for Nossa Órbita.
/// Shows no entry point before December 25, and does not infer watch dates
/// from a title's publication year or from incomplete legacy records.
class SaturnYearRecap {
  const SaturnYearRecap._();

  static bool visibleOn(DateTime today) =>
      today.month == 12 && today.day >= 25 && today.day <= 31;

  static bool _recordInYear(Object? value, int year) {
    if (value is! Map || value['updatedAt'] is! num) return false;
    final stamp = (value['updatedAt'] as num).toInt();
    if (stamp <= 0) return false;
    return DateTime.fromMillisecondsSinceEpoch(stamp).year == year;
  }

  /// Distinct shared titles with actual changes recorded during this year.
  static List<String> updatedSharedIds(
    Map<String, dynamic> records,
    Iterable<String> sharedIds,
    int year,
  ) {
    final ids = sharedIds.toSet();
    final changed = <String, int>{};
    for (final entry in records.entries) {
      final split = entry.key.indexOf(':');
      if (split <= 0) continue;
      final person = entry.key.substring(0, split);
      if (person != '0' && person != '1') continue;
      final workId = entry.key.substring(split + 1);
      if (!ids.contains(workId) || !_recordInYear(entry.value, year)) {
        continue;
      }
      final stamp = ((entry.value as Map)['updatedAt'] as num).toInt();
      if ((changed[workId] ?? 0) < stamp) changed[workId] = stamp;
    }
    return changed.keys.toList()
      ..sort((a, b) {
        final diff = changed[b]!.compareTo(changed[a]!);
        return diff == 0 ? a.compareTo(b) : diff;
      });
  }

  /// Number of non-empty personal reviews edited this year within the orbit.
  static int reviewsUpdatedInYear(
    Map<String, dynamic> records,
    Iterable<String> sharedIds,
    int year,
  ) {
    final ids = sharedIds.toSet();
    var count = 0;
    for (final entry in records.entries) {
      final split = entry.key.indexOf(':');
      if (split <= 0) continue;
      final person = entry.key.substring(0, split);
      if (person != '0' && person != '1') continue;
      if (!ids.contains(entry.key.substring(split + 1))) continue;
      final row = entry.value;
      if (!_recordInYear(row, year)) continue;
      if (row is Map &&
          (row['notes'] ?? '').toString().trim().isNotEmpty) {
        count++;
      }
    }
    return count;
  }
}
