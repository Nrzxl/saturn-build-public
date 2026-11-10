import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_story_synopsis.dart';

void main() {
  testWidgets('Old TVmaze summary uses the same expandable card as TMDB',
      (tester) async {
    final text = 'An original television series. ' * 25;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnStorySynopsis(description: text)))));
    final summary = find.text(text.trim());
    expect(summary, findsOneWidget);
    expect(tester.widget<Text>(summary).maxLines, 4);
    await tester.tap(find.byKey(const Key('saturn-story-synopsis-toggle')));
    await tester.pump();
    expect(tester.widget<Text>(summary).maxLines, isNull);
    expect(find.text('Recolher sinopse'), findsOneWidget);
  });

  testWidgets('Short summary does not add extra actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SaturnStorySynopsis(
        description: 'Uma história curta e emocionante.'))));
    expect(find.byKey(const Key('saturn-story-synopsis-toggle')), findsNothing);
  });
}
