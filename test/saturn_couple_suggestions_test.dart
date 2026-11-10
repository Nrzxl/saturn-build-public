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
}
