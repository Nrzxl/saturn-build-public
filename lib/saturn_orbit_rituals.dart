/// Weekly movie and individual monthly reading rituals.
///
/// For movies each person nominates one title and the couple makes a single
/// final choice. For reading each person independently chooses a different book
/// of the month. Every entry has its own timestamp for safe cloud merging.
/// Legacy 'month:...:selected' remains stored but is not a personal assignment.
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

  /// A personal monthly book cannot duplicate the other profile's book.
  static bool canChooseBook(Map<String, dynamic> ops, String period,
      int person, String candidateId) {
    if (!period.startsWith('month:') ||
        (person != 0 && person != 1) || candidateId.isEmpty) {
      return false;
    }
    return candidateId != workId(ops, nomination(period, 1 - person));
  }

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

  /// Only that person's book counts toward their reading progress.
  /// Old unfinished assignments remain pending after the month rolls over.
  static List<String> pendingBooks(Map<String, dynamic> ops,
      Map<String, dynamic> records, int person, DateTime now) {
    if (person != 0 && person != 1) return [];
    final lastKey = nomination(monthPeriod(now), person);
    final pattern = RegExp('^month:\\d{4}-\\d{2}:nomination:$person\

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
);
    final keys = ops.keys.where((key) =>
        pattern.hasMatch(key) && key.compareTo(lastKey) <= 0)
        .toList()..sort();
    return [
      for (final id in {
        for (final key in keys)
          if (workId(ops, key).isNotEmpty &&
              !bookFinishedAndRated(records, person, workId(ops, key)))
            workId(ops, key),
      }) id,
    ];
  }

  static bool hasAssignedBooks(Map<String, dynamic> ops, DateTime now,
      {required int person}) {
    if (person != 0 && person != 1) return false;
    final lastKey = nomination(monthPeriod(now), person);
    final pattern = RegExp('^month:\\d{4}-\\d{2}:nomination:$person\

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
);
    return ops.keys.any((key) =>
        pattern.hasMatch(key) && key.compareTo(lastKey) <= 0 &&
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
