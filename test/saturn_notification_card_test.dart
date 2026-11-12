import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_notification_card.dart';
import 'package:saturn_app/saturn_review_tiers.dart';
import 'package:saturn_app/saturn_zero_star_flies.dart';

void main() {
  Widget host({Object? rating, String kind = 'Filme', String poster = ''}) =>
      MaterialApp(home: Scaffold(body: Center(child: SizedBox(
        width: 380, child: SaturnNoticeCard(
          headline: 'Nova avaliação e resenha',
          title: 'Uma história real',
          author: 'Ela',
          when: '12/11 12:00',
          kind: kind,
          posterUrl: poster,
          rating: rating,
          unread: true,
          onTap: () {},
        ),
      ))));

  testWidgets('No personal score gives no invented award', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(SaturnZeroStarFlies), findsNothing);
    expect(find.text('Uma história real'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
  });

  testWidgets('Bronze and flies only for an explicit zero-star film',
      (tester) async {
    await tester.pumpWidget(host(rating: 0));
    expect(find.byType(SaturnZeroStarFlies), findsOneWidget);
    final title = tester.widget<Text>(find.text('Uma história real'));
    expect(title.style?.color, SaturnReviewTier.bronze.color);
  });

  testWidgets('Zero-star books never receive flies', (tester) async {
    await tester.pumpWidget(host(rating: 0, kind: 'Livro'));
    expect(find.byType(SaturnZeroStarFlies), findsNothing);
  });

  testWidgets('Silver and gold match the exact personal rating',
      (tester) async {
    await tester.pumpWidget(host(rating: 6));
    expect(tester.widget<Text>(find.text('Uma história real')).style?.color,
        SaturnReviewTier.prata.color);
    await tester.pumpWidget(host(rating: 8));
    expect(tester.widget<Text>(find.text('Uma história real')).style?.color,
        SaturnReviewTier.ouro.color);
    expect(find.byType(SaturnZeroStarFlies), findsNothing);
  });
}
