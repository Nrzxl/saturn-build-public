import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_premium_details.dart';

void main() {
  testWidgets('Sem Metacritic, não mostra notas de outros serviços',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {},
          tmdbScore: 7.8, tmdbVoteCount: 1200,
        ),
      )),
    ));
    expect(find.text('Público TMDB'), findsNothing);
    expect(find.text('7.8/10'), findsNothing);
    expect(find.text('IMDb'), findsNothing);
    expect(find.textContaining('Rotten Tomatoes'), findsNothing);
    expect(find.text('Metacritic · crítica'), findsNothing);
  });

  testWidgets('Somente Metacritic aparece com fontes múltiplas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {
            'imdb': '8.2/10',
            'rottenTomatoes': '92%',
            'metacritic': '71/100',
          },
          tmdbScore: 8.7,
          tmdbVoteCount: 900,
        ),
      )),
    ));
    expect(find.text('IMDb'), findsNothing);
    expect(find.text('8.2/10'), findsNothing);
    expect(find.textContaining('Rotten Tomatoes'), findsNothing);
    expect(find.text('92%'), findsNothing);
    expect(find.text('8.7/10'), findsNothing);
    expect(find.text('Metascore · crítica'), findsOneWidget);
    expect(find.text('71/100'), findsOneWidget);
  });

  testWidgets('Nota inválida não vira nota de crítica',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {
            'imdb': '9.9/10',
            'metacritic': '<script>alert(1)</script>',
          },
        ),
      )),
    ));
    expect(find.text('Metascore · crítica'), findsNothing);
    expect(find.text('9.9/10'), findsNothing);
    expect(find.text('Metacritic · crítica'), findsNothing);
  });

  testWidgets('Livros não recebem nota de cinema', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SaturnExternalRatings(
        isBook: true,
        ratings: {'metacritic': '70/100'},
      )),
    ));
    expect(find.text('Metascore · crítica'), findsNothing);
  });

  testWidgets('Sem nota verificável não exibe link ou bloco vazio',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          workTitle: 'Dark',
          isBook: false, ratings: {},
        ),
      )),
    ));
    expect(find.text('Ver no Metacritic'), findsNothing);
    expect(find.text('Metacritic · crítica'), findsNothing);
    expect(find.text('Ver no IMDb'), findsNothing);
    expect(find.text('Ver no Rotten Tomatoes'), findsNothing);
  });

  test('Busca oficial e validação da escala original', () {
    final source = SaturnExternalRatings.sourceSearch(
        'metacritic', 'The Batman');
    expect(source.host, 'www.metacritic.com');
    expect(Uri.decodeComponent(source.path), contains('The Batman'));
    expect(SaturnExternalRatings.validRating('metacritic', '75/100'), isTrue);
    expect(SaturnExternalRatings.validRating('metacritic', '101/100'), isFalse);
    expect(SaturnExternalRatings.validRating('metacritic', 'N/A'), isFalse);
  });
}
