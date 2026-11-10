import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  testWidgets('Nós permite consultar watchlist e livro do outro sem editar',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1180);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final series = Work('tmdb:tv:8100',
        'Série da Watchlist da Ela', 'Série', 'A série favorita.', 2025);
    final book = Work('openlibrary:/works/OL811W',
        'Livro do mês da Ela', 'Livro', 'O livro dela.', 2024);
    final month = SaturnOrbitRituals.monthPeriod(DateTime.now());
    final entry = {
      'status': 'Em andamento', 'notes': 'Lendo aos poucos',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        series.id: series.toJson(), book.id: book.toJson(),
      }),
      'watchlist_v1': jsonEncode({'0': [], '1': [series.id]}),
      'saturn_watchlist_ops': jsonEncode({
        '1:' + series.id: {
          'present': true, 'updatedAt': 10,
        },
      }),
      'records': jsonEncode({'1:' + book.id: entry}),
      'saturn_ritual_ops_v1': jsonEncode({
        SaturnOrbitRituals.nomination(month, 1): {
          'workId': book.id, 'updatedAt': 20,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final partner = find.byKey(const Key('saturn-partner-shelves'));
    await tester.scrollUntilVisible(partner, 190,
        scrollable: find.byType(Scrollable).first, maxScrolls: 70);
    expect(partner, findsOneWidget);
    expect(find.text('O universo de Ela'), findsOneWidget);
    expect(find.text('Série da Watchlist da Ela'), findsWidgets);
    final books = find.byKey(const Key('saturn-partner-filter-Livros'));
    await tester.ensureVisible(books);
    await tester.tap(books);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saturn-partner-book-of-month')),
        findsOneWidget);
    expect(find.text('Livro do mês da Ela'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('records')!) as Map;
    expect((stored['1:' + book.id] as Map)['notes'], 'Lendo aos poucos');
    final retained = jsonDecode(prefs.getString('watchlist_v1')!) as Map;
    expect(retained['1'], [series.id]);
  });
}
