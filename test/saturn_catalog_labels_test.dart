import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_catalog_labels.dart';

void main() {
  test('BR genres display movie and TV IDs without fabricated labels', () {
    expect(SaturnCatalogLabels.genreLine([28, 12, 18]),
        'Ação · Aventura');
    expect(SaturnCatalogLabels.genreLine([10764, 18]),
        'Reality · Drama');
    expect(SaturnCatalogLabels.genreLine([1234567]), '');
    expect(SaturnCatalogLabels.genreLine([]), '');
  });

  test('Technical details appear only when metadata is real', () {
    expect(SaturnCatalogLabels.technical(kind: 'Filme',
        runtimeMinutes: 104), '104 min');
    expect(SaturnCatalogLabels.technical(kind: 'Dorama',
        seasonCount: 1), '1 temporada');
    expect(SaturnCatalogLabels.technical(kind: 'Série',
        seasonCount: 4), '4 temporadas');
    expect(SaturnCatalogLabels.technical(kind: 'Filme'), isNull);
    expect(SaturnCatalogLabels.technical(kind: 'Anime'), isNull);
    expect(SaturnCatalogLabels.technical(kind: 'Filme',
        runtimeMinutes: 0), isNull);
  });
}
