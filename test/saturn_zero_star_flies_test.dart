import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_zero_star_flies.dart';

void main() {
  testWidgets('Zero-star flies stay inside artwork and never intercept taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 155, height: 200,
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(
              onTap: () => taps++,
              child: const ColoredBox(color: Colors.black)),
            const SaturnZeroStarFlies(),
          ]),
        ),
      ),
    ));
    expect(find.byType(SaturnZeroStarFlies), findsOneWidget);
    expect(find.descendant(
      of: find.byType(SaturnZeroStarFlies),
      matching: find.byType(CustomPaint)), findsOneWidget);
    await tester.tapAt(const Offset(70, 80));
    await tester.pump();
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reduced-motion disables the animated insects',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: SizedBox(width: 160, height: 200,
              child: SaturnZeroStarFlies()),
        ),
      ),
    ));
    expect(find.byType(SaturnZeroStarFlies), findsOneWidget);
    expect(find.descendant(
      of: find.byType(SaturnZeroStarFlies),
      matching: find.byType(CustomPaint)), findsNothing);
  });
}
