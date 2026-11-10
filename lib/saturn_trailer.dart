import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Show SATURN artwork first; instantiate the official iframe only after the
/// viewer chooses play. Its required branding/links remain unobscured.
class SaturnTrailerPreview extends StatefulWidget {
  const SaturnTrailerPreview({
    super.key, required this.youtubeId, this.alternativeIds = const [],
    this.storyPreview, this.heroMode = false,
    this.workTitle = '', this.workMetadata = '',
  });

  final String youtubeId;
  final List<String> alternativeIds;
  final Widget? storyPreview;
  final bool heroMode;
  final String workTitle;
  final String workMetadata;

  /// Browser Web/PWA: silent autoplay can start without a click when allowed.
  /// Never force an audible play; native builds retain their current behavior.
  static bool shouldAutoplay({required bool web, required bool hero}) =>
      web && hero;

  @override
  State<SaturnTrailerPreview> createState() => _SaturnTrailerPreviewState();
}

class _SaturnTrailerPreviewState extends State<SaturnTrailerPreview> {
  YoutubePlayerController? _controller;
  bool _muted = true;
  bool _exhausted = false;
  bool _pendingError = false;
  int _candidateIndex = 0;

  static bool validVideoId(String id) =>
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id);

  /// Browsers may reject autoplay because of local settings. Keep the
  /// SATURN Play button operational as a user-gesture fallback.
  @override
  void initState() {
    super.initState();
    _scheduleMutedAutoplay();
  }

  void _scheduleMutedAutoplay() {
    if (!SaturnTrailerPreview.shouldAutoplay(
        web: kIsWeb, hero: widget.heroMode)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller == null &&
          !_exhausted && _candidates.isNotEmpty) {
        _activateCandidate(0);
      }
    });
  }

  List<String> get _candidates => <String>{
    widget.youtubeId, ...widget.alternativeIds,
  }.where(validVideoId).take(4).toList(growable: false);

  @override
  void didUpdateWidget(covariant SaturnTrailerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.youtubeId == oldWidget.youtubeId &&
        listEquals(widget.alternativeIds, oldWidget.alternativeIds)) return;
    final old = _controller;
    _controller = null;
    _candidateIndex = 0;
    _pendingError = false;
    _exhausted = false;
    _muted = true;
    old?.close();
    _scheduleMutedAutoplay();
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _activateCandidate(int index) {
    final ids = _candidates;
    if (!mounted || index < 0 || index >= ids.length) {
      if (mounted) setState(() => _exhausted = true);
      return;
    }
    final replacement = YoutubePlayerController.fromVideoId(
      videoId: ids[index],
      // Silent autoplay is attempted on Web; blocked browsers retain the
      // SATURN Play button so the viewer can start with a gesture.
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true, playsInline: true,
        showControls: false, showFullscreenButton: false,
        showVideoAnnotations: false,
        enableCaption: true, captionLanguage: 'pt',
        interfaceLanguage: 'pt', privacyEnhancedMode: true,
        pointerEvents: PointerEvents.initial,
      ),
    );
    final previous = _controller;
    setState(() {
      _candidateIndex = index;
      _controller = replacement;
      _muted = true;
      _exhausted = false;
    });
    previous?.close();
  }

  void _handlePlayerError(YoutubeError error) {
    if (error == YoutubeError.none || _pendingError || !mounted) return;
    _pendingError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pendingError = false;
      final next = _candidateIndex + 1;
      if (next < _candidates.length) {
        _activateCandidate(next);
      } else {
        final previous = _controller;
        setState(() {
          _controller = null;
          _exhausted = true;
        });
        previous?.close();
      }
    });
  }

  Future<void> _togglePlayback() async {
    final player = _controller;
    if (player == null) {
      if (!_exhausted && _candidates.isNotEmpty) _activateCandidate(0);
      return;
    }
    try {
      if (await player.playerState == PlayerState.playing) {
        await player.pauseVideo();
      } else {
        await player.playVideo();
      }
    } catch (_) {
      // Some browsers need another explicit gesture to resume playback.
    }
  }

  Future<void> _toggleSound() async {
    final player = _controller;
    if (player == null) return;
    try {
      if (_muted) {
        await player.unMute();
        await player.setVolume(75);
      } else {
        await player.mute();
      }
      if (mounted) setState(() => _muted = !_muted);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível alterar o som.'),
        ));
      }
    }
  }

  Future<void> _searchOfficialTrailer() async {
    await launchUrl(Uri.https('www.youtube.com', '/results', {
      'search_query': widget.workTitle + ' trailer original oficial',
    }), mode: LaunchMode.externalApplication);
  }

  Widget _preview() => widget.storyPreview ?? Container(
    height: 240, alignment: Alignment.center,
    decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFF422438), Color(0xFF201924)])),
    child: const Icon(Icons.movie_filter_outlined,
      size: 62, color: Color(0xFFC6A477)),
  );

  Widget _videoSurface() {
    final player = _controller;
    if (player == null) {
      // The old Column overflowed the 16:9 stage and printed an error over
      // the controls. Keep the art, put error status in the controls row.
      return _preview();
    }
    return YoutubeValueBuilder(controller: player,
      builder: (context, value) {
        if (value.hasError) _handlePlayerError(value.error);
        return YoutubePlayer(
          key: ValueKey('saturn-youtube-' + _candidates[_candidateIndex]),
          controller: player, aspectRatio: 16 / 9);
      });
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;
    if (widget.heroMode) {
      // One cinematic stage: SATURN poster before Play, official trailer
      // afterward. No second work title, metadata panel or second card.
      // Controls stay *outside* the iframe so YouTube labels stay accessible.
      return Container(
        key: const Key('saturn-trailer-hero'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: const LinearGradient(colors: [
            Color(0xFF402639), Color(0xFF191923),
          ]),
          border: Border.all(color: const Color(0x665F465A)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            key: const Key('saturn-single-cinematic-stage'),
            aspectRatio: 16 / 9,
            child: _videoSurface(),
          ),
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 3, 8, 3),
              child: Row(children: [
                const Icon(Icons.movie_filter_outlined,
                    color: Color(0xFFC6A477), size: 18),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  _exhausted ? 'TRAILER INDISPONÍVEL'
                      : player == null ? 'ASSISTIR AO TRAILER'
                      : 'TRAILER OFICIAL',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFC6A477),
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.3),
                )),
                if (_exhausted)
                  IconButton.filledTonal(
                    key: const Key('saturn-trailer-find-alternative'),
                    tooltip: 'Procurar outro trailer oficial',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _searchOfficialTrailer)
                else if (player == null)
                  IconButton.filledTonal(
                    key: const Key('saturn-trailer-play-pause'),
                    tooltip: 'Reproduzir trailer',
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: _togglePlayback)
                else
                  YoutubeValueBuilder(
                    controller: player,
                    builder: (context, value) => IconButton.filledTonal(
                      key: const Key('saturn-trailer-play-pause'),
                      tooltip: value.playerState == PlayerState.playing
                          ? 'Pausar trailer' : 'Reproduzir trailer',
                      icon: Icon(value.playerState == PlayerState.playing
                          ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      onPressed: _togglePlayback)),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  key: const Key('saturn-trailer-mute'),
                  tooltip: _muted ? 'Ativar som' : 'Silenciar trailer',
                  icon: Icon(_muted
                      ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                  onPressed: player == null ? null : _toggleSound),
              ]),
            ),
          ),
        ]),
      );
    }
    return Container(
      key: widget.heroMode
          ? const Key('saturn-trailer-hero')
          : const Key('saturn-trailer-inline'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.heroMode ? 23 : 18),
        gradient: const LinearGradient(
          colors: [Color(0xFF402639), Color(0xFF191923)]),
        border: Border.all(color: const Color(0x665F465A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: _videoSurface(),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 13),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workTitle, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'serif',
                    color: Color(0xFFF2E8DF), fontSize: 21,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(_exhausted
                    ? 'Trailer indisponível · buscar outra versão'
                    : player == null
                        ? 'Reproduzir trailer · áudio original preferencial'
                        : 'Legendas PT-BR quando disponíveis no YouTube',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD0B8C7),
                    fontSize: 11)),
                Text(widget.workMetadata, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFBCA7B6),
                    fontSize: 10)),
              ])),
            if (_exhausted)
              IconButton.filledTonal(
                key: const Key('saturn-trailer-find-alternative'),
                tooltip: 'Buscar trailer oficial',
                icon: const Icon(Icons.search_rounded),
                onPressed: _searchOfficialTrailer)
            else if (player == null)
              IconButton.filledTonal(
                key: const Key('saturn-trailer-play-pause'),
                tooltip: 'Reproduzir trailer',
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: _togglePlayback)
            else
              YoutubeValueBuilder(
                controller: player,
                builder: (context, value) => IconButton.filledTonal(
                  key: const Key('saturn-trailer-play-pause'),
                  tooltip: value.playerState == PlayerState.playing
                      ? 'Pausar trailer' : 'Reproduzir trailer',
                  icon: Icon(value.playerState == PlayerState.playing
                      ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: _togglePlayback)),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              key: const Key('saturn-trailer-mute'),
              tooltip: _muted ? 'Ativar som' : 'Silenciar trailer',
              icon: Icon(_muted
                  ? Icons.volume_off_rounded : Icons.volume_up_rounded),
              onPressed: player == null ? null : _toggleSound),
          ]),
        ),
      ]),
    );
  }
}
