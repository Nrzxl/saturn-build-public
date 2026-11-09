/// Shared weekend and monthly rituals. Each participant may nominate one title.
/// The couple explicitly chooses one of the proposals. Entries are timestamped
/// independently so the offline/cloud merge can preserve both nominations.
class SaturnOrbitRituals {
  static String two(int number) => number.toString().padLeft(2, '0');

  static DateTime weekendSaturday(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final offset = now.weekday == DateTime.sunday ? -1
        : (DateTime.saturday - now.weekday + 7) % 7;
    return today.add(Duration(days: offset));
  }

  static String weekendPeriod(DateTime now) {
    final sat = weekendSaturday(now);
    return 'weekend:${sat.year}-${two(sat.month)}-${two(sat.day)}';
  }

  static String monthPeriod(DateTime now) =>
      'month:${now.year}-${two(now.month)}';

  static String nomination(String period, int person) =>
      '$period:nomination:$person';

  static String selection(String period) => '$period:selected';

  static String workId(Map<String, dynamic> ops, String key) {
    final row = ops[key];
    if (row is! Map) return '';
    final id = row['workId'];
    return id is String ? id : '';
  }

  static bool bookFinishedAndRated(Map<String, dynamic> records,
      int person, String workId) {
    if (workId.isEmpty || person < 0 || person > 1) return false;
    final record = records['$person:$workId'];
    if (record is! Map) return false;
    final complete = record['status'] == 'Concluído' ||
        record['status'] == 'Lido';
    final rating = record['rating'];
    return complete && rating is num && rating > 0;
  }

  /// Past books remain pending until read and rated, including next month.
  static List<String> pendingBooks(Map<String, dynamic> ops,
      Map<String, dynamic> records, int person, DateTime now) {
    final lastKey = '${monthPeriod(now)}:selected';
    final keys = ops.keys.where((key) =>
        RegExp(r'^month:\d{4}-\d{2}:selected$').hasMatch(key) &&
        key.compareTo(lastKey) <= 0).toList()..sort();
    return [
      for (final key in keys)
        if (workId(ops, key).isNotEmpty &&
            !bookFinishedAndRated(records, person, workId(ops, key)))
          workId(ops, key),
    ];
  }

  static bool hasAssignedBooks(Map<String, dynamic> ops, DateTime now) {
    final lastKey = '${monthPeriod(now)}:selected';
    return ops.keys.any((key) =>
        RegExp(r'^month:\d{4}-\d{2}:selected$').hasMatch(key) &&
        key.compareTo(lastKey) <= 0 &&
        workId(ops, key).isNotEmpty);
  }

  static String weekendLabel(DateTime now) {
    final sat = weekendSaturday(now);
    final sun = sat.add(const Duration(days: 1));
    return '${two(sat.day)}/${two(sat.month)}'
        '–${two(sun.day)}/${two(sun.month)}';
  }

  static const months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  static String monthLabel(DateTime now) =>
      '${months[now.month - 1]} de ${now.year}';
}
