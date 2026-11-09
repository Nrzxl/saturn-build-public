import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A verified TMDB trailer. Attempts silent inline autoplay when the sheet
/// opens; OS/YouTube policies may prevent it, so playback remains user-driven.
/// Never auto-play with audio enabled; leaving the details disposes the player.
class SaturnTrailerPreview extends StatefulWidget {
  final String youtubeId;

  const SaturnTrailerPreview({super.key, required this.youtubeId});

  @override
  State<SaturnTrailerPreview> createState() => _SaturnTrailerPreviewState();
}

class _SaturnTrailerPreviewState extends State<SaturnTrailerPreview> {
  YoutubePlayerController? _controller;
  bool _muted = true;

  static bool validVideoId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    if (!validVideoId(widget.youtubeId)) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true,
        playsInline: true,
        showControls: true,
        showFullscreenButton: true,
        privacyEnhancedMode: true,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SaturnTrailerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.youtubeId == oldWidget.youtubeId) return;
    _controller?.close();
    _controller = null;
    _muted = true;
    _setup();
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _toggleSound() async {
    final player = _controller;
    if (player == null) return;
    final next = !_muted;
    try {
      if (next) {
        await player.mute();
      } else {
        await player.unMute();
        await player.setVolume(75);
      }
      if (mounted) setState(() => _muted = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
            'O som não pôde ser alterado neste player.')));
      }
    }
  }

  Future<void> _openYouTube() async {
    if (!validVideoId(widget.youtubeId)) return;
    final url = Uri.https('www.youtube.com', '/watch', {
      'v': widget.youtubeId,
    });
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF211923),
        border: Border.all(color: const Color(0x776B4C57)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.play_circle_outline,
                color: Color(0xFFC6A477)),
            const SizedBox(width: 9),
            const Expanded(child: Text('TRAILER OFICIAL',
              style: TextStyle(
                color: Color(0xFFC6A477),
                letterSpacing: 1.5, fontSize: 11,
                fontWeight: FontWeight.bold),
            )),
            IconButton.filledTonal(
              tooltip: _muted ? 'Ativar som' : 'Silenciar trailer',
              icon: Icon(_muted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded),
              onPressed: _toggleSound,
            ),
          ]),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [
                Positioned.fill(child: Image.network(
                  'https://i.ytimg.com/vi/${widget.youtubeId}/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF211923)),
                )),
                YoutubePlayer(
                  controller: controller,
                  aspectRatio: 16 / 9,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 5),
          Row(children: [
            const Expanded(child: Text(
              'Player oficial • prévia automática sem som, '
              'quando permitida pelo aparelho.',
              style: TextStyle(
                fontSize: 10, color: Color(0xFFC9B2BC)),
            )),
            TextButton.icon(
              onPressed: _openYouTube,
              icon: const Icon(Icons.open_in_new, size: 15),
              label: const Text('YouTube'),
            ),
          ]),
        ],
      ),
    );
  }
}
