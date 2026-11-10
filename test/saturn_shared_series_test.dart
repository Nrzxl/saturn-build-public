import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  test('A série atual foi escolha dela; eu posso reservar a próxima', () {
    final ops = <String, dynamic>{};
    expect(SaturnOrbitRituals.canRegisterHerExistingSeries(ops), isTrue);
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 1);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 1), isFalse);
    ops['series:turn:0'] = {
      'workId': 'tmdb:tv:100', 'chosenBy': 1,
      'finished': false, 'updatedAt': 100,
    };
    final current = SaturnOrbitRituals.currentSeries(ops);
    expect(current?.workId, 'tmdb:tv:100');
    expect(current?.chosenBy, 1);
    expect(current?.queued, isFalse); // Legacy data is still active.
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 0);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 0), isTrue);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 1), isFalse);
    expect(SaturnOrbitRituals.canRegisterHerExistingSeries(ops), isFalse);
  });

  test('Fila Ela → Eu → Ela não interrompe a série atual', () {
    final ops = <String, dynamic>{
      'series:turn:0': {
        'workId': 'series:ela', 'chosenBy': 1,
        'finished': false, 'updatedAt': 10,
      },
      'series:turn:1': {
        'workId': 'series:eu', 'chosenBy': 0,
        'finished': false, 'queued': true, 'updatedAt': 20,
      },
    };
    expect(SaturnOrbitRituals.currentSeries(ops)?.workId, 'series:ela');
    expect(SaturnOrbitRituals.queuedSeries(ops), hasLength(1));
    expect(SaturnOrbitRituals.queuedSeries(ops).single.workId, 'series:eu');
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 1);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 1), isTrue);
    ops['series:turn:2'] = {
      'workId': 'series:ela2', 'chosenBy': 1,
      'finished': false, 'queued': true, 'updatedAt': 30,
    };
    expect(SaturnOrbitRituals.currentSeries(ops)?.workId, 'series:ela');
    expect(SaturnOrbitRituals.queuedSeries(ops), hasLength(2));
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 0);
    expect(SaturnOrbitRituals.nextSeriesNumber(ops), 3);
  });

  test('Apenas o autor pode trocar sua própria escolha ainda na fila', () {
    final ops = <String, dynamic>{
      'series:turn:0': {
        'workId': 'series:ela', 'chosenBy': 1, 'finished': false,
      },
      'series:turn:1': {
        'workId': 'series:eu', 'chosenBy': 0,
        'finished': false, 'queued': true,
      },
    };
    final queued = SaturnOrbitRituals.queuedSeries(ops).single;
    expect(SaturnOrbitRituals.mayEditQueuedSeries(ops, queued, 0), isTrue);
    expect(SaturnOrbitRituals.mayEditQueuedSeries(ops, queued, 1), isFalse);
    expect(SaturnOrbitRituals.canUseSeriesWork(ops, 'series:ela'), isFalse);
    expect(SaturnOrbitRituals.canUseSeriesWork(ops, 'series:eu'), isFalse);
    expect(SaturnOrbitRituals.canUseSeriesWork(
        ops, 'series:eu', replacingNumber: 1), isTrue);
    expect(SaturnOrbitRituals.canUseSeriesWork(ops, 'series:nova'), isTrue);
    ops['series:turn:1'] = {
      'workId': 'series:eu', 'chosenBy': 0,
      'finished': true, 'queued': false,
    };
    expect(SaturnOrbitRituals.mayEditQueuedSeries(ops, queued, 0), isFalse);
  });

  test('Ao terminar a atual, uma fila preservada pode ser promovida', () {
    final ops = <String, dynamic>{
      'series:turn:0': {
        'workId': 'series:ela', 'chosenBy': 1,
        'finished': false, 'updatedAt': 10,
      },
      'series:turn:1': {
        'workId': 'series:eu', 'chosenBy': 0,
        'finished': false, 'queued': true, 'updatedAt': 20,
      },
      'series:turn:2': {
        'workId': 'series:ela2', 'chosenBy': 1,
        'finished': false, 'queued': true, 'updatedAt': 30,
      },
    };
    ops['series:turn:0'] = {
      'workId': 'series:ela', 'chosenBy': 1,
      'finished': true, 'updatedAt': 40,
    };
    ops['series:turn:1'] = {
      'workId': 'series:eu', 'chosenBy': 0,
      'finished': false, 'queued': false, 'updatedAt': 41,
    };
    expect(SaturnOrbitRituals.currentSeries(ops)?.workId, 'series:eu');
    expect(SaturnOrbitRituals.queuedSeries(ops).single.workId, 'series:ela2');
    expect(SaturnOrbitRituals.seriesTurns(ops), hasLength(3));
  });

  test('Dados incompatíveis não viram escolhas válidas', () {
    final ops = <String, dynamic>{
      'series:turn:bad': {'workId': 'false', 'chosenBy': 0},
      'series:turn:2': {'workId': '', 'chosenBy': 1},
      'series:turn:3': {'workId': 'stray', 'chosenBy': 5},
      'month:2026-11:nomination:0': {'workId': 'book'},
    };
    expect(SaturnOrbitRituals.seriesTurns(ops), isEmpty);
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 1);
    expect(SaturnOrbitRituals.currentSeries(ops), isNull);
  });
}
