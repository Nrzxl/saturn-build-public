
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_couple_insights.dart';

void main() {
  test('cada perfil preserva sua própria nota, resenha e status', () {
    final data = <String, dynamic>{
      '0:a': {'status': 'Concluído', 'rating': 8.5, 'notes': 'Meu filme'},
      '1:a': {'status': 'Concluído', 'rating': 9.5, 'notes': 'Nosso filme'},
      '0:b': {'status': 'Em andamento', 'notes': 'Começamos juntos'},
      '1:b': {'status': 'Quero conhecer'},
      '1:c': {'status': 'Assistido'},
    };
    final original = data['1:a']['notes'];
    final insights = SaturnCoupleInsights(['a', 'b', 'c', 'c'], data);
    expect(insights.ids, ['a', 'b', 'c']);
    expect(insights.completedTogether, 1);
    expect(insights.inProgress, 1);
    expect(insights.memories, 2);
    expect(insights.reviewsFromBoth, 1);
    expect(insights.profile(0, 'a')['rating'], 8.5);
    expect(insights.profile(1, 'a')['rating'], 9.5);
    expect(insights.profileStatus(0, 'a'), 'Assistido');
    expect(insights.profileStatus(0, 'a', book: true), 'Lido');
    expect(insights.profileStatus(0, 'c'), 'Ainda sem registro');
    expect(data['1:a']['notes'], original);
  });

  test('momentos são filtros de leitura, sem mudar compartilhamentos', () {
    final saved = <String, dynamic>{
      '0:complete': {'status': 'Lido'},
      '1:complete': {'status': 'Concluído'},
      '0:active': {'status': 'Em andamento'},
      '1:pending': {'status': 'Concluído'},
    };
    final insights = SaturnCoupleInsights(
      ['complete', 'active', 'pending'], saved);
    expect(insights.matches('complete', 'Vividas por nós'), isTrue);
    expect(insights.matches('active', 'Em andamento'), isTrue);
    expect(insights.matches('pending', 'Para descobrir'), isTrue);
    expect(insights.matches('pending', 'Vividas por nós'), isFalse);
    expect(insights.matches('active', 'Para descobrir'), isFalse);
    expect(insights.matches('pending', 'Todas'), isTrue);
    expect(insights.ids, ['complete', 'active', 'pending']);
  });

  test('vazio, dados legados e notas inesperadas não fabricam momentos', () {
    final insights = SaturnCoupleInsights(['x', 'x', 'y'], {
      '0:x': 'registro inválido',
      '1:x': {'rating': null, 'notes': 12},
      '0:y': {'status': 'Concluído'},
    });
    expect(insights.completedTogether, 0);
    expect(insights.inProgress, 0);
    expect(insights.reviewsFromBoth, 0);
    expect(insights.profile(0, 'x'), isEmpty);
    expect(insights.profileStatus(1, 'missing'), 'Ainda sem registro');
  });
}
