import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_couple_suggestions.dart';

void main() {
  test('Cada perfil pode recomendar sem editar a lista do outro', () {
    final ops = <String, dynamic>{};
    final first = SaturnCoupleSuggestion.send(
      ops, from: 0, workId: 'tmdb:movie:1', at: 100);
    final second = SaturnCoupleSuggestion.send(
      ops, from: 1, workId: 'openlibrary:/books/OL3M', at: 100);
    expect(first, isNot(second));
    expect(SaturnCoupleSuggestion.read(ops, recipient: 1).single.from, 0);
    expect(SaturnCoupleSuggestion.read(ops, recipient: 0).single.from, 1);
    expect((ops[first] as Map)['status'], 'pending');
    expect(SaturnCoupleSuggestion.answer(
      ops, first, by: 0, status: 'accepted', at: 200), isFalse);
    expect(SaturnCoupleSuggestion.answer(
      ops, first, by: 1, status: 'accepted', at: 200), isTrue);
    expect((ops[first] as Map)['updatedAt'], 200);
    expect((ops[second] as Map)['status'], 'pending');
    expect(SaturnCoupleSuggestion.answer(
      ops, first, by: 1, status: 'dismissed', at: 300), isFalse);
  });

  test('Toque duplo gera uma única sugestão pendente e mantém estado',
      () {
    final data = <String, dynamic>{};
    final one = SaturnCoupleSuggestion.send(
      data, from: 0, workId: 'tmdb:movie:99', at: 1234);
    final two = SaturnCoupleSuggestion.send(
      data, from: 0, workId: 'tmdb:movie:99', at: 1235);
    expect(two, one);
    expect(data, hasLength(1));
    expect(SaturnCoupleSuggestion.alreadySent(data,
      from: 0, workId: 'tmdb:movie:99')?.status, 'pending');
    expect(SaturnCoupleSuggestion.visible(data), hasLength(1));
    expect(SaturnCoupleSuggestion.answer(data, one,
        by: 1, status: 'accepted', at: 1236), isTrue);
    expect(SaturnCoupleSuggestion.send(data,
        from: 0, workId: 'tmdb:movie:99', at: 1237), one);
    expect(data, hasLength(1));
  });

  test('Sugestão recusada permite novo envio sem apagar o histórico', () {
    final data = <String, dynamic>{};
    final old = SaturnCoupleSuggestion.send(
      data, from: 1, workId: 'book', at: 200);
    expect(SaturnCoupleSuggestion.answer(data, old,
      by: 0, status: 'dismissed', at: 210), isTrue);
    final newer = SaturnCoupleSuggestion.send(
      data, from: 1, workId: 'book', at: 220);
    expect(newer, isNot(old));
    expect(data, hasLength(2));
    expect(SaturnCoupleSuggestion.visible(data), hasLength(1));
    expect(SaturnCoupleSuggestion.visible(data).single.key, newer);
  });

  test('IDs únicos mesmo quando timestamp coincide; dados ruins ignorados', () {
    final ops = <String, dynamic>{};
    final a = SaturnCoupleSuggestion.send(
      ops, from: 0, workId: 'a', at: 1000);
    final b = SaturnCoupleSuggestion.send(
      ops, from: 0, workId: 'b', at: 1000);
    expect(a, isNot(b));
    ops['suggestion:bad'] = {'to': 3, 'status': 'pending'};
    expect(SaturnCoupleSuggestion.read(ops), hasLength(2));
    expect(SaturnCoupleSuggestion.answer(
      ops, b, by: 1, status: 'dismissed', at: 1500), isTrue);
    expect(SaturnCoupleSuggestion.read(ops).first.key, b);
  });
  test('Sender may withdraw pending/accepted suggestions without deleting history', () {
    final ops = <String, dynamic>{};
    final first = SaturnCoupleSuggestion.send(
      ops, from: 0, workId: 'tmdb:movie:24', at: 1000);
    expect(SaturnCoupleSuggestion.withdraw(
      ops, first, by: 1, at: 1001), isFalse);
    expect(SaturnCoupleSuggestion.withdraw(
      ops, first, by: 0, at: 1002), isTrue);
    expect((ops[first] as Map)['status'], 'withdrawn');
    expect(SaturnCoupleSuggestion.visible(ops), isEmpty);
    expect(SaturnCoupleSuggestion.alreadySent(
      ops, from: 0, workId: 'tmdb:movie:24'), isNull);
    final again = SaturnCoupleSuggestion.send(
      ops, from: 0, workId: 'tmdb:movie:24', at: 1010);
    expect(again, isNot(first));
    expect(SaturnCoupleSuggestion.answer(
      ops, again, by: 1, status: 'accepted', at: 1020), isTrue);
    expect(SaturnCoupleSuggestion.withdraw(
      ops, again, by: 0, at: 1030), isTrue);
    expect(SaturnCoupleSuggestion.visible(ops), isEmpty);
    expect(ops, hasLength(2));
  });

}
