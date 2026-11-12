import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_metallic_halo.dart';

void main() {
  testWidgets('Halo envolve a imagem sem criar nome ou selo textual',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 160, height: 240,
        child: SaturnMetallicHalo(
          color: Color(0xFFE3BF70), child: Text('Capa da obra'))),
      ),
    )));
    expect(find.text('Capa da obra'), findsOneWidget);
    expect(find.text('OURO'), findsNothing);
    expect(find.byType(AnimatedContainer), findsWidgets);
    await tester.pump(const Duration(milliseconds: 4450));
    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sem resenha, nenhum metal é desenhado', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SaturnMetallicHalo(color: null, child: Text('Sem halo')),
    )));
    expect(find.text('Sem halo'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
  });
  testWidgets('Mutual zero intensifies bronze without changing tier',
      (tester) async {
    const bronze = Color(0xFFC38A62);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SaturnMetallicHalo(color: bronze, partnerColor: bronze,
        intenseBronze: true, child: Text('Zero em dobro')),
    )));
    final halo = tester.widget<SaturnMetallicHalo>(
        find.byType(SaturnMetallicHalo));
    expect(halo.intenseBronze, isTrue);
    final shell = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first);
    expect((shell.padding! as EdgeInsets).left, greaterThan(3));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Shared halo combines two real tiers and glows on a match',
      (tester) async {
    const gold = Color(0xFFE3BF70);
    const silver = Color(0xFFBDC8D4);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 150, height: 230,
        child: SaturnMetallicHalo(
          color: gold, partnerColor: silver, child: Text('Nossa capa')))),
    )));
    expect(find.text('Nossa capa'), findsOneWidget);
    final split = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first);
    final border = split.decoration! as BoxDecoration;
    expect((border.gradient! as LinearGradient).colors.length, 6);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SaturnMetallicHalo(
        color: gold, partnerColor: gold, child: Text('Mesma nota')),
    )));
    expect(find.text('Mesma nota'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4300));
    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.takeException(), isNull);
  });

}
