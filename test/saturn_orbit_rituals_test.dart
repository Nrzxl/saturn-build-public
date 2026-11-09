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
      'month:2026-10:selected': {'workId': book, 'updatedAt': 10},
    };
    final records = <String, dynamic>{
      '0:$book': {'status': 'Lido', 'rating': null},
      '1:$book': {'status': 'Em andamento', 'rating': 9},
    };
    final today = DateTime(2026, 11, 9);
    expect(SaturnOrbitRituals.hasAssignedBooks(ops, today), isTrue);
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 0, today), [book]);
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 1, today), [book]);
    records['0:$book'] = {'status': 'Concluído', 'rating': 8.5};
    records['1:$book'] = {'status': 'Lido', 'rating': 9};
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 0, today), isEmpty);
    expect(SaturnOrbitRituals.pendingBooks(ops, records, 1, today), isEmpty);
  });

  test('Sem livro escolhido, não há carinha triste; ignora meses futuros', () {
    final today = DateTime(2026, 11, 9);
    final ops = <String, dynamic>{
      'month:2026-12:selected': {'workId': 'futuro', 'updatedAt': 50},
      'month:2026-10:selected': {'workId': '', 'updatedAt': 100},
    };
    expect(SaturnOrbitRituals.hasAssignedBooks(ops, today), isFalse);
    expect(SaturnOrbitRituals.pendingBooks(ops, {}, 0, today), isEmpty);
  });
}
