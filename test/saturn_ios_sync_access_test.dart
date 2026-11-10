import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saturn_app/main.dart';

void main() {
  testWidgets('iPhone estreito abre sincronização pelo cabeçalho',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    final sync = find.byKey(const Key('saturn-header-sync'));
    expect(sync, findsOneWidget);
    await tester.tap(sync);
    await tester.pumpAndSettle();
    expect(find.text('Nossa Órbita · Sincronização'), findsOneWidget);
  });

  testWidgets('iPhone mantém acesso alternativo sem usar ícone superior',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SaturnApp());
    await tester.pumpAndSettle();
    final home = find.byKey(const Key('saturn-home-sync-shortcut'));
    expect(home, findsOneWidget);
    await tester.tap(home);
    await tester.pumpAndSettle();
    expect(find.text('Nossa Órbita · Sincronização'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nós dois'));
    await tester.pumpAndSettle();
    final couple = find.byKey(const Key('saturn-couple-sync-shortcut'));
    expect(couple, findsOneWidget);
    await tester.tap(couple);
    await tester.pumpAndSettle();
    expect(find.text('Nossa Órbita · Sincronização'), findsOneWidget);
  });
}
