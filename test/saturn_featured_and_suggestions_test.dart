import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final hero = find.byKey(const Key('saturn-feature-swipe'));
    expect(find.descendant(of: hero,
        matching: find.text('DA SUA WATCHLIST · PARA VOCÊ')), findsNothing);
    expect(find.descendant(of: hero,
        matching: find.text('EM DESTAQUE · DESCUBRA')), findsNothing);
    expect(find.descendant(of: hero,
        matching: find.textContaining('Bem-vinda')), findsNothing);
    expect(find.descendant(of: hero,
        matching: find.textContaining('na coleção')), findsNothing);
    expect(find.text('EVERY STORY HAS ITS ORBIT'), findsOneWidget);
    final label = find.byKey(const Key('saturn-featured-title'));
    expect(tester.widget<Text>(label.last).data, first.title);
    expect(find.byKey(Key('saturn-hero-art-${first.id}')), findsOneWidget);
    expect(find.text('1/2'), findsNothing);
    // Timed rotation must crossfade the artwork without input.
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, second.title);
    expect(find.byKey(Key('saturn-hero-art-${second.id}')), findsOneWidget);
    final swiper = find.byKey(const Key('saturn-feature-swipe'));
    expect(swiper, findsOneWidget);
    expect(find.byKey(const Key('saturn-feature-previous')), findsNothing);
    expect(find.byKey(const Key('saturn-feature-next')), findsNothing);
    // User-requested direction: drag LEFT to go back, RIGHT to advance.
    await tester.drag(swiper, const Offset(-150, 0));
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, first.title);
    await tester.drag(swiper, const Offset(150, 0));
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, second.title);
    // Minor accidental movements must not trigger another slide.
    await tester.drag(swiper, const Offset(13, 0));
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, second.title);
    // A horizontal mouse drag works on desktop, not only touch.
    await tester.drag(swiper, const Offset(-140, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, first.title);
    // Arrow keys remain an accessible alternative to the hidden buttons.
    Focus.of(tester.element(swiper)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.widget<Text>(label.last).data, second.title);
    expect(find.text('Descobrir histórias'), findsNothing);
    expect(find.text('Ver detalhes'), findsNothing);
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
  testWidgets('Carousel is no longer artificially restricted to eight films',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final works = [
      for (var i = 0; i < 11; i++)
        Work('tmdb:movie:${10000 + i}', 'Filme ${i + 1}', 'Filme',
            'Filme com capa', 2025,
            posterUrl: 'https://example.com/poster-$i.jpg'),
    ];
    SharedPreferences.setMockInitialValues({
      'catalog_saved': jsonEncode({
        for (final work in works) work.id: work.toJson(),
      }),
      'watchlist_v1': jsonEncode({
        '0': [for (final work in works) work.id], '1': [],
      }),
    });
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    // No visible chevrons or numeric overlays; catalog still has >8 titles.
    final swipe = find.byKey(const Key('saturn-feature-swipe'));
    expect(swipe, findsOneWidget);
    expect(find.text('1/11'), findsNothing);
    expect(find.byKey(const Key('saturn-feature-previous')), findsNothing);
    expect(find.byKey(const Key('saturn-feature-next')), findsNothing);
    for (var i = 0; i < 9; i++) {
      await tester.drag(swipe, const Offset(135, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('10/11'), findsNothing);
    expect(tester.widget<Text>(
      find.byKey(const Key('saturn-featured-title')).last).data, 'Filme 10');
  });

}
