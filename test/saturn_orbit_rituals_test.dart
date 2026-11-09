import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  test('Fim de semana inclui sábado e domingo e muda no ano novo', () {
    expect(SaturnOrbitRituals.weekendPeriod(DateTime(2026, 11, 9)),
        'weekend:2026-11-14');
    expect(SaturnOrbitRituals.weekendPeriod(DateTime(2026, 11, 14)),
        'weekend:2026-11-14');
    expect(SaturnOrbitRituals.weekendPeriod(DateTime(2026, 11, 15)),
        'weekend:2026-11-14');
    expect(SaturnOrbitRituals.weekendPeriod(DateTime(2026, 12, 31)),
        'weekend:2027-01-02');
    expect(SaturnOrbitRituals.weekendLabel(DateTime(2026, 11, 9)),
        '14/11–15/11');
    expect(SaturnOrbitRituals.monthLabel(DateTime(2026, 11, 9)),
        'novembro de 2026');
  });

  test('Indicações são distintas e escolha final é explícita', () {
    const period = 'weekend:2026-11-14';
    final ops = <String, dynamic>{
      SaturnOrbitRituals.nomination(period, 0):
          {'workId': 'filme-0', 'updatedAt': 100},
      SaturnOrbitRituals.nomination(period, 1):
          {'workId': 'filme-1', 'updatedAt': 110},
      SaturnOrbitRituals.selection(period):
          {'workId': 'filme-1', 'updatedAt': 120},
    };
    expect(SaturnOrbitRituals.workId(
        ops, SaturnOrbitRituals.nomination(period, 0)), 'filme-0');
    expect(SaturnOrbitRituals.workId(
        ops, SaturnOrbitRituals.nomination(period, 1)), 'filme-1');
    expect(SaturnOrbitRituals.workId(
        ops, SaturnOrbitRituals.selection(period)), 'filme-1');
    ops[SaturnOrbitRituals.nomination(period, 0)] = {
      'workId': '', 'updatedAt': 180,
    };
    expect(SaturnOrbitRituals.workId(
        ops, SaturnOrbitRituals.nomination(period, 0)), isEmpty);
  });

  test('Carinha triste persiste até marcar leitura e dar nota', () {
    const book = 'openlibrary:/works/OL123W';
    final ops = <String, dynamic>{
      'month:2026-10:nomination:0': {'workId': book, 'updatedAt': 10},
      'month:2026-10:nomination:1': {'workId': 'other-book', 'updatedAt': 11},
    };
    final records = <String, dynamic>{
      '0:$book': {'status': 'Lido', 'rating': null},
      '1:other-book': {'status': 'Em andamento', 'rating': 9},
    };
    final today = DateTime(2026, 11, 9);
    expect(SaturnOrbitRituals.hasAssignedBooks(
      ops, today, person: 0), isTrue);
    expect(SaturnOrbitRituals.hasAssignedBooks(
      ops, today, person: 1), isTrue);
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 0, today), [book]);
    expect(SaturnOrbitRituals.pendingBooks(
      ops, records, 1, today), ['other-book']);
    records['0:$book'] = {'status': 'Concluído', 'rating': 8.5};
    records['1:other-book'] = {'status': 'Lido', 'rating': 9};
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 0, today), isEmpty);
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 1, today), isEmpty);
  });


  test('Cada perfil escolhe livro diferente, sem seleção coletiva', () {
    const period = 'month:2026-11';
    final ops = <String, dynamic>{
      SaturnOrbitRituals.nomination(period, 0): {
        'workId': 'livro-eu', 'updatedAt': 200,
      },
      'month:2026-11:selected': {
        'workId': 'livro-antigo-da-versao-anterior', 'updatedAt': 100,
      },
    };
    expect(SaturnOrbitRituals.canChooseBook(
      ops, period, 1, 'livro-eu'), isFalse);
    expect(SaturnOrbitRituals.canChooseBook(
      ops, period, 1, 'livro-ela'), isTrue);
    ops[SaturnOrbitRituals.nomination(period, 1)] = {
      'workId': 'livro-ela', 'updatedAt': 210,
    };
    expect(SaturnOrbitRituals.canChooseBook(
      ops, period, 0, 'livro-ela'), isFalse);
    expect(SaturnOrbitRituals.canChooseBook(
      ops, period, 0, 'livro-eu'), isTrue);
    final today = DateTime(2026, 11, 9);
    expect(SaturnOrbitRituals.pendingBooks(
      ops, {}, 0, today), ['livro-eu']);
    expect(SaturnOrbitRituals.pendingBooks(
      ops, {}, 1, today), ['livro-ela']);
  });

  test('Sem livro escolhido, não há carinha triste; ignora meses futuros', () {
    final today = DateTime(2026, 11, 9);
    final ops = <String, dynamic>{
      'month:2026-12:nomination:0': {
        'workId': 'futuro', 'updatedAt': 50,
      },
      'month:2026-10:nomination:0': {
        'workId': '', 'updatedAt': 100,
      },
      // Old collective monthly choice must NOT be assigned to either person.
      'month:2026-10:selected': {
        'workId': 'legacy-book', 'updatedAt': 120,
      },
    };
    expect(SaturnOrbitRituals.hasAssignedBooks(
      ops, today, person: 0), isFalse);
    expect(SaturnOrbitRituals.hasAssignedBooks(
      ops, today, person: 1), isFalse);
    expect(SaturnOrbitRituals.pendingBooks(ops, {}, 0, today), isEmpty);
  });
}
