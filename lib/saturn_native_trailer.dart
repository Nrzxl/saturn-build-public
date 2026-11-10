import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'saturn_premium_details.dart';

/// Fully native playback reserved for licensed MP4/HLS trailers served by
/// a publisher-owned CDN. The hostname is an explicit build-time allowlist;
/// YouTube streams must remain in the official embedded player.
class SaturnNativeTrailer extends StatefulWidget {
  const SaturnNativeTrailer({
    super.key,
    required this.mediaUrl,
    required this.rightsConfirmed,
    this.subtitleUrl = '',
  });

  final String mediaUrl;
  final bool rightsConfirmed;
  /// Publisher-provided PT-BR WebVTT, not extracted YouTube subtitles.
  final String subtitleUrl;

  static const licensedHost = String.fromEnvironment(
    'SATURN_NATIVE_MEDIA_HOST');

  static bool canUseNative(String url, {required bool rightsConfirmed}) {
    if (!rightsConfirmed || licensedHost.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' ||
        uri.host != licensedHost || uri.userInfo.isNotEmpty) {
      return false;
    }
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.m3u8');
  }

  static bool canUseSubtitle(String url, {required bool rightsConfirmed}) {
    if (!rightsConfirmed || licensedHost.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' &&
        uri.host == licensedHost && uri.userInfo.isEmpty &&
        uri.path.toLowerCase().endsWith('.vtt');
  }

  @override
  State<SaturnNativeTrailer> createState() => _SaturnNativeTrailerState();
}

class _SaturnNativeTrailerState extends State<SaturnNativeTrailer> {
  VideoPlayerController? _controller;
  bool _muted = true;
  bool _loading = true;
  bool _failed = false;
  bool _captionsAvailable = false;
  bool _captionsOn = true;

  Future<ClosedCaptionFile> _licensedCaptions() async {
    final uri = Uri.parse(widget.subtitleUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 ||
        response.bodyBytes.length > 256 * 1024 ||
        !response.body.trimLeft().startsWith('WEBVTT')) {
      throw const FormatException('Legenda WebVTT inválida.');
    }
    return WebVTTCaptionFile(response.body);
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!SaturnNativeTrailer.canUseNative(
      widget.mediaUrl, rightsConfirmed: widget.rightsConfirmed)) {
      if (mounted) setState(() {
        _failed = true;
        _loading = false;
      });
      return;
    }
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      if (SaturnNativeTrailer.canUseSubtitle(widget.subtitleUrl,
          rightsConfirmed: widget.rightsConfirmed)) {
        try {
          await controller.setClosedCaptionFile(_licensedCaptions());
          if (mounted) setState(() => _captionsAvailable = true);
        } catch (_) {
          // Unavailable subtitles never block a licensed video.
        }
      }
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _sound() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final muted = !_muted;
    await controller.setVolume(muted ? 0 : 0.8);
    if (mounted) setState(() => _muted = muted);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SaturnDetailSection(
        title: 'Trailer',
        icon: Icons.video_file_outlined,
        child: Text(
          'Este arquivo não está licenciado ou disponível neste aparelho.',
          style: TextStyle(color: satinSubdued),
        ),
      );
    }
    final player = _controller;
    return SaturnDetailSection(
      title: 'Trailer • reprodução nativa SATURN',
      icon: Icons.play_circle_filled_outlined,
      child: Column(children: [
        if (_loading)
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator(
              color: satinGold)),
          )
        else if (player != null && player.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: player.value.aspectRatio,
              child: Stack(fit: StackFit.expand, children: [
                VideoPlayer(player),
                if (_captionsAvailable && _captionsOn)
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: player,
                    builder: (context, value, child) => IgnorePointer(
                      child: ClosedCaption(
                        text: value.caption.text,
                        textStyle: const TextStyle(
                          fontSize: 16, color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 7,
                              color: Colors.black)],
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        Row(children: [
          IconButton(
            tooltip: player?.value.isPlaying == true
                ? 'Pausar' : 'Reproduzir',
            icon: Icon(player?.value.isPlaying == true
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline),
            onPressed: player == null
                ? null
                : () async {
                    if (player.value.isPlaying) {
                      await player.pause();
                    } else {
                      await player.play();
                    }
                    if (mounted) setState(() {});
                  },
          ),
          IconButton(
            tooltip: _muted ? 'Ativar som' : 'Silenciar',
            icon: Icon(_muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded),
            onPressed: _sound,
          ),
          if (_captionsAvailable)
            IconButton(
              key: const Key('saturn-native-subtitles'),
              tooltip: _captionsOn
                  ? 'Desativar legendas SATURN PT-BR'
                  : 'Ativar legendas SATURN PT-BR',
              icon: Icon(_captionsOn
                  ? Icons.subtitles_rounded : Icons.subtitles_off_rounded),
              onPressed: () => setState(() => _captionsOn = !_captionsOn),
            ),
          const Expanded(child: Text(
            'Prévia licenciada · legendas SATURN quando autorizadas.',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 10, color: satinSubdued),
          )),
        ]),
      ]),
    );
  }
}
