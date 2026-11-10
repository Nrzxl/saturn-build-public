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
}
