import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_premium_details.dart';

void main() {
  testWidgets('Apenas as fontes que realmente têm notas aparecem',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {},
          tmdbScore: 7.8, tmdbVoteCount: 1200,
        ),
      )),
    ));
    expect(find.text('Público TMDB'), findsOneWidget);
    expect(find.text('7.8/10'), findsOneWidget);
    expect(find.textContaining('1200 votos'), findsOneWidget);
    expect(find.text('IMDb'), findsNothing);
    expect(find.text('Metacritic · crítica'), findsNothing);
    expect(find.textContaining('não estão disponíveis'), findsOneWidget);
  });

  testWidgets('Pontuações externas reais são atribuídas corretamente',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {
            'imdb': '8.2/10',
            'rottenTomatoes': '92%',
            'metacritic': '71/100',
          },
        ),
      )),
    ));
    expect(find.text('IMDb'), findsOneWidget);
    expect(find.text('8.2/10'), findsOneWidget);
    expect(find.text('Rotten Tomatoes · crítica'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('Metacritic · crítica'), findsOneWidget);
    expect(find.text('71/100'), findsOneWidget);
    expect(find.textContaining('audiência Rotten Tomatoes'), findsOneWidget);
  });

  testWidgets('Dados inválidos não viram pontuações de crítica',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: SaturnExternalRatings(
          isBook: false, ratings: {
            'imdb': 'N/A',
            'rottenTomatoes': '99%%',
            'metacritic': '<script>alert(1)</script>',
          },
        ),
      )),
    ));
    expect(find.text('IMDb'), findsNothing);
    expect(find.text('Rotten Tomatoes · crítica'), findsNothing);
    expect(find.text('Metacritic · crítica'), findsNothing);
    expect(find.textContaining('não estão disponíveis'), findsOneWidget);
  });

  testWidgets('Livros não recebem nota de cinema',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SaturnExternalRatings(
        isBook: true,
        ratings: {'imdb': '8.2/10'},
        tmdbScore: 8.2, tmdbVoteCount: 20,
      )),
    ));
    expect(find.text('Crítica e audiência'), findsNothing);
  });

  test('Valida faixas e escalas sem transformar ausências em números', () {
    expect(SaturnExternalRatings.validRating('imdb', '8.2/10'), isTrue);
    expect(SaturnExternalRatings.validRating('rottenTomatoes', '82%'), isTrue);
    expect(SaturnExternalRatings.validRating('metacritic', '75/100'), isTrue);
    expect(SaturnExternalRatings.validRating('imdb', 'N/A'), isFalse);
    expect(SaturnExternalRatings.validRating('rottenTomatoes', '999%'), isFalse);
  });
}
