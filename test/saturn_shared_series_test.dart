import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_rituals.dart';

void main() {
  test('A série atual foi escolha dela; a próxima é dele', () {
    final ops = <String, dynamic>{};
    expect(SaturnOrbitRituals.canRegisterHerExistingSeries(ops), isTrue);
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 1);
    expect(SaturnOrbitRituals.nextSeriesNumber(ops), 0);
    ops['series:turn:0'] = {
      'workId': 'tmdb:tv:100', 'chosenBy': 1,
      'finished': false, 'updatedAt': 100,
    };
    final current = SaturnOrbitRituals.currentSeries(ops);
    expect(current?.workId, 'tmdb:tv:100');
    expect(current?.chosenBy, 1);
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 0);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 0), isFalse);
    expect(SaturnOrbitRituals.canRegisterHerExistingSeries(ops), isFalse);
    ops['series:turn:0'] = {
      'workId': 'tmdb:tv:100', 'chosenBy': 1,
      'finished': true, 'updatedAt': 200,
    };
    expect(SaturnOrbitRituals.currentSeries(ops), isNull);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 0), isTrue);
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 1), isFalse);
    expect(SaturnOrbitRituals.nextSeriesNumber(ops), 1);
  });

  test('Escolhas alternam Ela → Eu → Ela sem perder histórico', () {
    final ops = <String, dynamic>{
      'series:turn:0': {
        'workId': 'series:ela', 'chosenBy': 1,
        'finished': true, 'updatedAt': 10,
      },
      'series:turn:1': {
        'workId': 'series:eu', 'chosenBy': 0,
        'finished': false, 'updatedAt': 20,
      },
    };
    expect(SaturnOrbitRituals.currentSeries(ops)?.workId, 'series:eu');
    expect(SaturnOrbitRituals.nextSeriesPicker(ops), 1);
    ops['series:turn:1'] = {
      'workId': 'series:eu', 'chosenBy': 0,
      'finished': true, 'updatedAt': 30,
    };
    expect(SaturnOrbitRituals.mayChooseSeries(ops, 1), isTrue);
    expect(SaturnOrbitRituals.seriesTurns(ops), hasLength(2));
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
