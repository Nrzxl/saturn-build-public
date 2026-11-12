/// Cross-profile activity inferred only from verified shared SATURN data.
/// No additional backend table or device permission is required to display
/// this inbox. Background OS push is not implemented here.
class SaturnNotice {
  const SaturnNotice({
    required this.id, required this.kind, required this.actor,
    required this.workId, required this.title, required this.at,
  });

  final String id;
  final String kind;
  final int actor;
  final String workId;
  final String title;
  final int at;

  String get headline => switch (kind) {
    'review' => 'Nova avaliação e resenha',
    'suggestion' => 'Uma nova sugestão para você',
    'series' => 'Nova série na Nossa Maratona',
    'book' => 'Livro do mês concluído',
    _ => 'Novidade na Nossa Órbita',
  };
}

class SaturnNotificationInbox {
  const SaturnNotificationInbox._();

  static int _stamp(Object? value) {
    if (value is! num || !value.isFinite) return 0;
    final date = value.toInt();
    return date > 0 ? date : 0;
  }

  static bool _finished(Object? value) =>
      value == 'Concluído' || value == 'Lido';

  /// Reads partner-authored activity from already-synchronized records.
  /// Event IDs are stable across reconnects, re-opening the inbox and
  /// independent merge passes. New reviews use the record's last edit time.
  static List<SaturnNotice> forProfile({
    required int profile,
    required Map<String, dynamic> records,
    required Map<String, dynamic> rituals,
    required Map<String, String> titles,
  }) {
    if (profile != 0 && profile != 1) return const [];
    final other = 1 - profile;
    final notices = <String, SaturnNotice>{};

    String titleFor(String id) {
      final title = titles[id]?.trim() ?? '';
      return title.isEmpty ? 'Um título da Nossa Órbita' : title;
    }

    for (final entry in records.entries) {
      final prefix = '$other:';
      if (!entry.key.startsWith(prefix) || entry.value is! Map) continue;
      final record = entry.value as Map;
      final workId = entry.key.substring(prefix.length);
      final score = record['rating'];
      final notes = (record['notes'] ?? '').toString().trim();
      final at = _stamp(record['updatedAt']);
      if (workId.isEmpty || score is! num || !score.isFinite ||
          score < 0 || score > 10 || notes.isEmpty || at <= 0) {
        continue;
      }
      final id = 'review:$other:$workId:$at';
      notices[id] = SaturnNotice(id: id, kind: 'review',
        actor: other, workId: workId, title: titleFor(workId), at: at);
    }

    for (final entry in rituals.entries) {
      final row = entry.value;
      if (row is! Map) continue;
      final workId = row['workId'];
      if (workId is! String || workId.isEmpty) continue;
      if (entry.key.startsWith('suggestion:')) {
        if (row['from'] != other || row['to'] != profile ||
            !{'pending', 'accepted'}.contains(row['status'])) continue;
        final at = _stamp(row['createdAt'] ?? row['updatedAt']);
        if (at <= 0) continue;
        final id = 'suggestion:${entry.key}';
        notices[id] = SaturnNotice(id: id, kind: 'suggestion',
          actor: other, workId: workId, title: titleFor(workId), at: at);
      } else if (RegExp(r'^series:turn:[0-9]+$').hasMatch(entry.key)) {
        // New records distinguish the person who actually registered the
        // choice from the chooser of an old show being imported into SATURN.
        if (row['chosenBy'] != other ||
            (row['createdBy'] is int && row['createdBy'] != other) ||
            row['finished'] == true) continue;
        final at = _stamp(row['createdAt'] ?? row['updatedAt']);
        if (at <= 0) continue;
        final id = 'series:${entry.key}';
        notices[id] = SaturnNotice(id: id, kind: 'series',
          actor: other, workId: workId, title: titleFor(workId), at: at);
      } else if (RegExp(r'^month:[0-9]{4}-[0-9]{2}:nomination:[01]$')
          .hasMatch(entry.key) && entry.key.endsWith(':$other')) {
        final record = records['$other:$workId'];
        if (record is! Map || !_finished(record['status'])) continue;
        final at = _stamp(record['updatedAt']);
        if (at <= 0) continue;
        final id = 'book:${entry.key}:$workId';
        notices[id] = SaturnNotice(id: id, kind: 'book',
          actor: other, workId: workId, title: titleFor(workId), at: at);
      }
    }

    final ordered = notices.values.toList();
    ordered.sort((a, b) {
      final time = b.at.compareTo(a.at);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
    return ordered.take(80).toList(growable: false);
  }

  static int unreadCount(List<SaturnNotice> notices, {
    required int baseline,
    required Set<String> read,
  }) => notices.where((item) =>
      item.at > baseline && !read.contains(item.id)).length;
}
