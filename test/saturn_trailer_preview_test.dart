import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:saturn_app/saturn_trailer.dart';
import 'package:saturn_app/saturn_native_trailer.dart';

void main() {
  test('Web/PWA may autoplay silently; native and nonhero never do', () {
    expect(SaturnTrailerPreview.shouldAutoplay(web: true, hero: true), isTrue);
    expect(SaturnTrailerPreview.shouldAutoplay(web: true, hero: false), isFalse);
    expect(SaturnTrailerPreview.shouldAutoplay(web: false, hero: true), isFalse);
  });

  testWidgets('Story opens with SATURN artwork and existing controls only',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SaturnTrailerPreview(
        youtubeId: 'abcdefghijk',
        alternativeIds: ['123456789ab'],
        workTitle: 'Gladiador',
        heroMode: true,
        storyPreview: SizedBox(height: 225,
          child: Column(children: [
            Text('Arte cinematográfica SATURN'),
            Text('Gladiador'),
          ])),
      ),
    )));
    expect(find.text('Arte cinematográfica SATURN'), findsOneWidget);
    expect(find.text('Gladiador'), findsOneWidget);
    expect(find.byKey(const Key('saturn-single-cinematic-stage')),
        findsOneWidget);
    expect(find.text('ASSISTIR AO TRAILER'), findsOneWidget);
    expect(find.byKey(const Key('saturn-trailer-play-pause')),
        findsOneWidget);
    expect(find.byKey(const Key('saturn-trailer-mute')),
        findsOneWidget);
    // The YouTube iframe must NOT even exist until the viewer taps play.
    expect(find.byType(YoutubePlayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('SATURN native captions require an authorized HTTPS .vtt host', () {
    expect(SaturnNativeTrailer.canUseSubtitle(
      'https://youtube.com/hidden.vtt', rightsConfirmed: false), isFalse);
    expect(SaturnNativeTrailer.canUseSubtitle(
      'http://example.com/trailer.vtt', rightsConfirmed: true), isFalse);
    expect(SaturnNativeTrailer.canUseSubtitle(
      'https://example.com/trailer.srt', rightsConfirmed: true), isFalse);
  });
}
