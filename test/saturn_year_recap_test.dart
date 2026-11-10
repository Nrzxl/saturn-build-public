import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_year_recap.dart';

void main() {
  test('A retrospectiva só é revelada de 25 a 31 de dezembro', () {
    expect(SaturnYearRecap.visibleOn(DateTime(2026, 11, 30)), isFalse);
    expect(SaturnYearRecap.visibleOn(DateTime(2026, 12, 24, 23, 59)), isFalse);
    expect(SaturnYearRecap.visibleOn(DateTime(2026, 12, 25)), isTrue);
    expect(SaturnYearRecap.visibleOn(DateTime(2026, 12, 31, 23, 59)), isTrue);
    expect(SaturnYearRecap.visibleOn(DateTime(2027, 1, 1)), isFalse);
  });

  test('Resumos usam somente registros compartilhados datados no ano', () {
    final thisYear = DateTime(2026, 11, 9).millisecondsSinceEpoch;
    final lastYear = DateTime(2025, 12, 25).millisecondsSinceEpoch;
    final records = <String, dynamic>{
      '0:tmdb:tv:10': {
        'notes': 'Adoramos', 'status': 'Concluído', 'updatedAt': thisYear,
      },
      '1:tmdb:tv:10': {
        'notes': 'Também adorei', 'updatedAt': thisYear + 1,
      },
      '1:tmdb:tv:11': {
        'notes': '', 'updatedAt': thisYear - 10,
      },
      '0:tmdb:tv:12': {
        'notes': 'Outro ano', 'updatedAt': lastYear,
      },
      '0:not-shared': {
        'notes': 'Não entra', 'updatedAt': thisYear + 99,
      },
      'bad-record': {'updatedAt': thisYear},
    };
    final shared = ['tmdb:tv:10', 'tmdb:tv:11', 'tmdb:tv:12'];
    expect(SaturnYearRecap.updatedSharedIds(records, shared, 2026),
        ['tmdb:tv:10', 'tmdb:tv:11']);
    expect(SaturnYearRecap.reviewsUpdatedInYear(records, shared, 2026), 2);
    expect(SaturnYearRecap.updatedSharedIds(records, shared, 2027), isEmpty);
  });

  test('Sem datas reais não inventa atividades para retrospectiva', () {
    final records = <String, dynamic>{
      '0:a': {'status': 'Concluído'},
      '1:a': {'notes': 'Gostei', 'updatedAt': 0},
    };
    expect(SaturnYearRecap.updatedSharedIds(records, ['a'], 2026), isEmpty);
    expect(SaturnYearRecap.reviewsUpdatedInYear(records, ['a'], 2026), 0);
  });
}
