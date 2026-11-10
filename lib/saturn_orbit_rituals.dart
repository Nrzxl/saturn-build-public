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

  /// Each partner has one independent book per month. Previous assignments
  /// stay pending until that partner marks the book read and gives a rating.
  static List<String> pendingBooks(Map<String, dynamic> ops,
      Map<String, dynamic> records, int person, DateTime now) {
    if (person != 0 && person != 1) return [];
    // Only books from months that have ended are overdue.
    final previousMonth = DateTime(now.year, now.month, 0);
    final lastKey = nomination(monthPeriod(previousMonth), person);
    final pattern = RegExp(
        '^month:[0-9]{4}-[0-9]{2}:nomination:$person' + r'$');
    final keys = ops.keys.where((key) =>
        pattern.hasMatch(key) && key.compareTo(lastKey) <= 0)
        .toList()..sort();
    final pending = <String>{};
    for (final key in keys) {
      final id = workId(ops, key);
      if (id.isNotEmpty && !bookFinishedAndRated(records, person, id)) {
        pending.add(id);
      }
    }
    return pending.toList(growable: false);
  }

  /// Former shared month:selected entries do not assign a book to anyone.
  static bool hasAssignedBooks(Map<String, dynamic> ops, DateTime now,
      {required int person}) {
    if (person != 0 && person != 1) return false;
    final lastKey = nomination(monthPeriod(now), person);
    final pattern = RegExp(
        '^month:[0-9]{4}-[0-9]{2}:nomination:$person' + r'$');
    return ops.keys.any((key) =>
        pattern.hasMatch(key) && key.compareTo(lastKey) <= 0 &&
        workId(ops, key).isNotEmpty);
  }

  static String readingFace(Map<String, dynamic> ops,
      Map<String, dynamic> records, int person, DateTime now) {
    if (pendingBooks(ops, records, person, now).isNotEmpty) return '😢';
    final current = workId(ops, nomination(monthPeriod(now), person));
    if (current.isNotEmpty) {
      return bookFinishedAndRated(records, person, current) ? '😊' : '📖';
    }
    return hasAssignedBooks(ops, now, person: person) ? '😊' : '';
  }

  /// A shared show is chosen in turns, unlike weekend film nominations.
  static const String seriesPrefix = 'series:turn:';

  static List<SaturnSeriesTurn> seriesTurns(Map<String, dynamic> ops) {
    final items = <SaturnSeriesTurn>[];
    final pattern = RegExp(r'^series:turn:([0-9]+)$');
    for (final entry in ops.entries) {
      final match = pattern.firstMatch(entry.key);
      if (match == null || entry.value is! Map) continue;
      final row = entry.value as Map;
      final number = int.tryParse(match.group(1)!);
      final id = row['workId'];
      final person = row['chosenBy'];
      if (number == null || number < 0 || number > 100000 ||
          id is! String || id.isEmpty ||
          (person != 0 && person != 1)) continue;
      items.add(SaturnSeriesTurn(
        number: number, workId: id, chosenBy: person as int,
        finished: row['finished'] == true,
        queued: row['queued'] == true));
    }
    items.sort((a, b) => a.number.compareTo(b.number));
    return items;
  }

  /// Active and queued shows are separate: planning must never replace
  /// what the couple is currently watching.
  static SaturnSeriesTurn? currentSeries(Map<String, dynamic> ops) {
    for (final turn in seriesTurns(ops)) {
      if (!turn.finished && !turn.queued) return turn;
    }
    return null;
  }

  static List<SaturnSeriesTurn> queuedSeries(Map<String, dynamic> ops) =>
      seriesTurns(ops)
          .where((turn) => !turn.finished && turn.queued)
          .toList(growable: false);

  static int nextSeriesPicker(Map<String, dynamic> ops) {
    final turns = seriesTurns(ops);
    return turns.isEmpty ? 1 : 1 - turns.last.chosenBy;
  }

  /// The next partner can reserve a show while the current one plays.
  /// The very first entry is registered as her already-current choice.
  static bool mayChooseSeries(Map<String, dynamic> ops, int person) =>
      (person == 0 || person == 1) &&
      seriesTurns(ops).isNotEmpty &&
      nextSeriesPicker(ops) == person;

  static bool mayEditQueuedSeries(
      Map<String, dynamic> ops, SaturnSeriesTurn turn, int person) {
    if (person != turn.chosenBy || turn.finished || !turn.queued) {
      return false;
    }
    return seriesTurns(ops).any((item) =>
        item.number == turn.number && item.workId == turn.workId &&
        item.chosenBy == person && item.queued && !item.finished);
  }

  static bool canUseSeriesWork(Map<String, dynamic> ops, String workId,
      {int? replacingNumber}) =>
      workId.isNotEmpty && !seriesTurns(ops).any((turn) =>
          !turn.finished && turn.workId == workId &&
          turn.number != replacingNumber);

  /// An existing show chosen by partner 1 can be registered once without
  /// impersonating her profile or editing a personal review.
  static bool canRegisterHerExistingSeries(Map<String, dynamic> ops) =>
      seriesTurns(ops).isEmpty;

  static int nextSeriesNumber(Map<String, dynamic> ops) {
    final turns = seriesTurns(ops);
    return turns.isEmpty ? 0 : turns.last.number + 1;
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

class SaturnSeriesTurn {
  const SaturnSeriesTurn({
    required this.number, required this.workId,
    required this.chosenBy, required this.finished,
    this.queued = false,
  });
  final int number;
  final String workId;
  final int chosenBy;
  final bool finished;
  final bool queued;
}
