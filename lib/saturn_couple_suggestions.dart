/// A one-to-one private recommendation in the shared SATURN ritual document.
/// Stored under its own stamped key so sync never overwrites another message.
/// Receiving a recommendation NEVER changes the other person's watchlist.
class SaturnCoupleSuggestion {
  const SaturnCoupleSuggestion({
    required this.key, required this.workId, required this.from,
    required this.to, required this.updatedAt, required this.status,
  });

  final String key;
  final String workId;
  final int from;
  final int to;
  final int updatedAt;
  final String status;

  static const prefix = 'suggestion:';
  static const statuses = <String>{'pending', 'accepted', 'dismissed'};

  static List<SaturnCoupleSuggestion> read(
      Map<String, dynamic> data, {int? recipient}) {
    final result = <SaturnCoupleSuggestion>[];
    for (final entry in data.entries) {
      if (!entry.key.startsWith(prefix) || entry.value is! Map) continue;
      final row = entry.value as Map;
      final from = row['from'];
      final to = row['to'];
      final workId = (row['workId'] ?? '').toString();
      final status = (row['status'] ?? '').toString();
      final stamp = row['updatedAt'];
      if (from is! int || to is! int || from == to ||
          !{0, 1}.contains(from) || !{0, 1}.contains(to) ||
          workId.isEmpty || !statuses.contains(status) ||
          stamp is! num || (recipient != null && to != recipient)) {
        continue;
      }
      result.add(SaturnCoupleSuggestion(
        key: entry.key, workId: workId, from: from, to: to,
        status: status, updatedAt: stamp.toInt(),
      ));
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  /// Pending or accepted suggestions are considered already sent.
  /// Dismissed suggestions can be sent again on a later occasion.
  static SaturnCoupleSuggestion? alreadySent(
      Map<String, dynamic> ops, {required int from, required String workId}) {
    for (final item in read(ops)) {
      if (item.from == from && item.to == 1 - from &&
          item.workId == workId && item.status != 'dismissed') {
        return item;
      }
    }
    return null;
  }

  /// Read-only presentation that collapses historical duplicate sends.
  /// Never erases existing events from the shared sync document.
  static List<SaturnCoupleSuggestion> visible(
      Map<String, dynamic> ops) {
    final seen = <String>{};
    return [
      for (final item in read(ops))
        if (item.status != 'dismissed' &&
            seen.add('${item.from}:${item.to}:${item.workId}'))
          item,
    ];
  }

  static String send(Map<String, dynamic> ops, {
    required int from, required String workId, required int at,
  }) {
    if (!{0, 1}.contains(from) || workId.trim().isEmpty || at <= 0) {
      throw ArgumentError('Invalid suggestion');
    }
    // Idempotent even if someone taps twice or a slow iPhone does not
    // immediately repaint the button after a synced write.
    final existing = alreadySent(ops, from: from, workId: workId);
    if (existing != null) return existing.key;
    final to = 1 - from;
    // Preserve distinct recommendations even if sent in the same millisecond.
    var key = '$prefix$from:$at';
    var suffix = 1;
    while (ops.containsKey(key)) {
      key = '$prefix$from:$at:${suffix++}';
    }
    ops[key] = {
      'from': from, 'to': to, 'workId': workId,
      'status': 'pending', 'updatedAt': at,
    };
    return key;
  }

  static bool answer(Map<String, dynamic> ops, String key, {
    required int by, required String status, required int at,
  }) {
    if (!{'accepted', 'dismissed'}.contains(status)) return false;
    final value = ops[key];
    if (value is! Map || value['to'] != by ||
        value['status'] != 'pending') return false;
    ops[key] = {
      ...value.map((key, value) => MapEntry(key.toString(), value)),
      'status': status,
      'updatedAt': at,
    };
    return true;
  }
}
