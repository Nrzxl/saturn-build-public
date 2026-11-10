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

  static String send(Map<String, dynamic> ops, {
    required int from, required String workId, required int at,
  }) {
    if (!{0, 1}.contains(from) || workId.trim().isEmpty || at <= 0) {
      throw ArgumentError('Invalid suggestion');
    }
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
