import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('Minha Watchlist troca coleções por Já visto e atualiza estado',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1180);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const movie = Work('tmdb:movie:31415', 'Filme para assistir',
        'Filme', 'Uma história real', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({movie.id: movie.toJson()}),
      'watchlist_v1': jsonEncode({'0': [movie.id], '1': []}),
      'records': '{}',
    });

    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();

    final doneAction = find.byKey(
        const Key('saturn-home-completed-tmdb:movie:31415'));
    expect(doneAction, findsOneWidget);
    expect(find.byKey(
        const Key('saturn-recommend-collections-tmdb:movie:31415')),
        findsNothing);
    expect(tester.widget<IconButton>(doneAction).tooltip,
        'Marcar como visto');

    await tester.ensureVisible(doneAction);
    await tester.tap(doneAction);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final records = jsonDecode(prefs.getString('records')!) as Map;
    final watch = jsonDecode(prefs.getString('watchlist_v1')!) as Map;
    expect((records['0:tmdb:movie:31415'] as Map)['status'], 'Concluído');
    expect(watch['0'], isNot(contains(movie.id)));
  });

  testWidgets('Minha Estante usa Marcar como lido sem apagar o livro',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const book = Work('openlibrary:/books/OL551M', 'Meu livro',
        'Livro', 'Uma leitura real', 2026);
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({book.id: book.toJson()}),
      'watchlist_v1': jsonEncode({'0': [book.id], '1': []}),
      'records': '{}',
    });

    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    final doneAction = find.byKey(
        const Key('saturn-home-completed-openlibrary:/books/OL551M'));
    await tester.scrollUntilVisible(
        doneAction, 300, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<IconButton>(doneAction).tooltip,
        'Marcar como lido');

    await tester.tap(doneAction);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final records = jsonDecode(prefs.getString('records')!) as Map;
    final works = jsonDecode(prefs.getString('catalog_saved')!) as Map;
    expect((records['0:openlibrary:/books/OL551M'] as Map)['status'],
        'Concluído');
    expect(works.containsKey(book.id), isTrue);
  });
}
