import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_notification_inbox.dart';

void main() {
  test('Only the partner generates deduplicated real activity', () {
    const base = 1780000000000;
    final records = <String, dynamic>{
      '1:film': {
        'rating': 9, 'notes': 'Minha crítica', 'updatedAt': base + 100,
      },
      '0:own': {
        'rating': 10, 'notes': 'Eu escrevi', 'updatedAt': base + 110,
      },
      '1:without-comment': {
        'rating': 8, 'notes': '', 'updatedAt': base + 115,
      },
      '1:book': {'status': 'Lido', 'updatedAt': base + 120},
    };
    final rituals = <String, dynamic>{
      'suggestion:1:$base': {
        'from': 1, 'to': 0, 'workId': 'film',
        'createdAt': base + 80, 'updatedAt': base + 81,
        'status': 'pending',
      },
      'suggestion:1:withdrawn': {
        'from': 1, 'to': 0, 'workId': 'film',
        'createdAt': base + 90, 'updatedAt': base + 91,
        'status': 'withdrawn',
      },
      'series:turn:7': {
        'workId': 'show', 'chosenBy': 1, 'createdBy': 1,
        'createdAt': base + 105, 'updatedAt': base + 107,
        'finished': false, 'queued': true,
      },
      'series:turn:6': {
        // Registering her existing show from his profile is not a new
        // partner-authored choice.
        'workId': 'imported', 'chosenBy': 1, 'createdBy': 0,
        'createdAt': base + 60, 'updatedAt': base + 60,
        'finished': false,
      },
      'month:2026-11:nomination:1': {
        'workId': 'book', 'updatedAt': base + 50,
      },
    };
    const titles = <String, String>{
      'film': 'Filme real', 'show': 'Série real', 'book': 'Livro real',
    };
    List<SaturnNotice> notices() =>
        SaturnNotificationInbox.forProfile(
            profile: 0, records: records, rituals: rituals, titles: titles);

    final first = notices();
    expect(first.map((e) => e.kind).toSet(),
        {'review', 'suggestion', 'series', 'book'});
    expect(first, hasLength(4));
    expect(first.map((e) => e.id).toSet(), hasLength(4));
    expect(first.map((e) => e.id).toList(),
        notices().map((e) => e.id).toList());
    expect(first.any((e) => e.workId == 'own' ||
        e.workId == 'imported'), isFalse);
    expect(first.first.title, 'Livro real');
    final read = <String>{first.first.id};
    expect(SaturnNotificationInbox.unreadCount(first,
        baseline: base, read: read), 3);
    expect(SaturnNotificationInbox.unreadCount(first,
        baseline: base + 500, read: const {}), 0);

    // A new saved review has its own event; no duplicate after syncing.
    records['1:film'] = {
      'rating': 9, 'notes': 'Editei minha resenha',
      'updatedAt': base + 200,
    };
    final second = notices();
    expect(second, hasLength(4));
    expect(second.first.id, contains('review:1:film:'));
    expect(second.where((e) => e.kind == 'review'), hasLength(1));
  });

  testWidgets('Header inbox shows partner activity and read-all dismisses badge',
      (tester) async {
    const film = Work('tmdb:movie:101', 'Filme da outra pessoa',
        'Filme', 'Sinopse', 2026, provider: 'TMDB');
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'saturn_notifications_baseline_0': 1,
      'saturn_notifications_baseline_1': 1,
      'records': jsonEncode({
        '1:${film.id}': {
          'rating': 8,
          'notes': 'Adorei!',
          'updatedAt': 1780000000100,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saturn-header-notifications')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-notifications-badge')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('saturn-header-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('Nova avaliação e resenha'), findsOneWidget);
    expect(find.textContaining('Filme da outra pessoa'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saturn-notifications-read-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saturn-notifications-badge')),
        findsNothing);
  });
}
