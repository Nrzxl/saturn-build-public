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
