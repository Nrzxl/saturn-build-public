import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_review_tiers.dart';

void main() {
  test('Bronze, prata e ouro respeitam os limites reais de estrelas', () {
    SaturnReviewTier? rank(double score) =>
      SaturnReviewClassification.of({'rating': score * 2,
        'notes': 'Minha resenha'});
    expect(rank(0), SaturnReviewTier.bronze);
    expect(rank(1), SaturnReviewTier.bronze);
    expect(rank(1.5), SaturnReviewTier.bronze);
    expect(rank(2), SaturnReviewTier.prata);
    expect(rank(3), SaturnReviewTier.prata);
    expect(rank(3.5), SaturnReviewTier.prata);
    expect(rank(4), SaturnReviewTier.ouro);
    expect(rank(4.5), SaturnReviewTier.ouro);
    expect(rank(5), SaturnReviewTier.ouro);
  });

  test('O halo exige nota pessoal e comentário escrito', () {
    expect(SaturnReviewClassification.of(
      {'rating': 10.0, 'notes': ''}), isNull);
    expect(SaturnReviewClassification.of(
      {'rating': 10.0, 'notes': '  '}), isNull);
    expect(SaturnReviewClassification.of(
      {'rating': null, 'notes': 'Adorei!'}), isNull);
    expect(SaturnReviewClassification.of(
      {'rating': -1, 'notes': 'Ruim'}), isNull);
    expect(SaturnReviewClassification.of(
      {'rating': 11, 'notes': 'Boa obra'}), isNull);
    expect(SaturnReviewClassification.of(
      {'rating': double.nan, 'notes': 'Tentei avaliar'}), isNull);
    expect(SaturnReviewClassification.of(null), isNull);
    expect(SaturnReviewClassification.of({
      'rating': 9.0, 'notes': 'Duas sessões emocionantes!',
      'description': 'Sinopse importada',
    }), SaturnReviewTier.ouro);
    expect(SaturnReviewClassification.of({
      'rating': 9.0, 'description': 'Sinopse importada',
    }), isNull);
  });

  test('Ordenação de alto para baixo é estável e mantém não avaliados', () {
    final rows = <Map<String, dynamic>>[
      {'id': 'bronze', 'rating': 2, 'notes': 'Ruim'},
      {'id': 'sem', 'rating': 10, 'notes': ''},
      {'id': 'ouro', 'rating': 10, 'notes': 'Excelente'},
      {'id': 'prata', 'rating': 6, 'notes': 'Ok'},
      {'id': 'ouro2', 'rating': 8, 'notes': 'Bom'},
      {'id': 'prata2', 'rating': 6, 'notes': 'Também bom'},
    ];
    final sorted = SaturnReviewClassification.sorted(rows, (r) => r);
    expect(sorted.map((e) => e['id']).toList(),
        ['ouro', 'ouro2', 'prata', 'prata2', 'bronze', 'sem']);
    expect(SaturnReviewClassification.priority(SaturnReviewTier.ouro), 0);
    expect(SaturnReviewClassification.priority(null), 3);
  });

  test('Escala legada 0–10 é convertida corretamente para cinco estrelas', () {
    expect(SaturnReviewClassification.stars(
      {'rating': 8.5}), 4.25);
    expect(SaturnReviewClassification.stars(
      {'rating': 0}), 0);
    expect(SaturnReviewClassification.stars({}), isNull);
    expect(SaturnReviewTier.ouro.label, 'OURO');
    expect(SaturnReviewTier.prata.label, 'PRATA');
    expect(SaturnReviewTier.bronze.label, 'BRONZE');
  });
}
