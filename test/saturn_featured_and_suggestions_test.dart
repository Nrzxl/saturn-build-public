import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Destaque alterna filmes reais da Watchlist no celular',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const first = Work('tmdb:movie:100', 'Filme do meu universo',
      'Filme', 'Sinopse A', 2025,
      posterUrl: 'https://example.com/poster-one.jpg',
      genreIds: [18]);
    const second = Work('tmdb:movie:200', 'Outro filme preferido',
      'Filme', 'Sinopse B', 2024,
      posterUrl: 'https://example.com/poster-two.jpg',
      genreIds: [18, 10749]);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        first.id: first.toJson(), second.id: second.toJson(),
      }),
      'watchlist_v1': jsonEncode({
        '0': [first.id, second.id], '1': [],
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    expect(find.text('DA SUA WATCHLIST · PARA VOCÊ'), findsOneWidget);
    final label = find.byKey(const Key('saturn-featured-title'));
    expect(tester.widget<Text>(label).data, first.title);
    // Timed rotation must happen without any user input.
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(tester.widget<Text>(label).data, second.title);
    await tester.tap(find.byKey(const Key('saturn-feature-previous')));
    await tester.pump();
    expect(tester.widget<Text>(label).data, first.title);
    await tester.tap(find.byKey(const Key('saturn-feature-next')));
    await tester.pump();
    expect(tester.widget<Text>(label).data, second.title);
  });

  testWidgets('Sugestão de outra pessoa só altera Watchlist quando aceita',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const film = Work('tmdb:movie:300', 'Filme que Ela Recomenda',
      'Filme', 'Sinopse.', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({film.id: film.toJson()}),
      'watchlist_v1': jsonEncode({'0': [], '1': []}),
      'saturn_ritual_ops_v1': jsonEncode({
        'suggestion:1:100': {
          'workId': film.id,
          'from': 1, 'to': 0, 'status': 'pending', 'updatedAt': 100,
        },
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final suggestion = find.byKey(const Key('saturn-couple-suggestions'));
    await tester.scrollUntilVisible(suggestion, 180,
      scrollable: find.byType(Scrollable).first, maxScrolls: 60);
    expect(suggestion, findsOneWidget);
    expect(find.text('Filme que Ela Recomenda'), findsWidgets);
    final add = find.byKey(
      const Key('saturn-suggestion-accept-suggestion:1:100'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final lists = jsonDecode(prefs.getString('watchlist_v1')!) as Map;
    expect(lists['0'], contains(film.id));
    expect(lists['1'], isEmpty);
    final ops = jsonDecode(prefs.getString('saturn_ritual_ops_v1')!) as Map;
    expect((ops['suggestion:1:100'] as Map)['status'], 'accepted');
  });
}
