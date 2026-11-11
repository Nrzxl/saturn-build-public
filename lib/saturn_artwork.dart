import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';

/// High-definition, edition-preserving art and compact color extraction.
/// Network palette work is deferred until a card is actually on screen.
class SaturnArtwork {
  const SaturnArtwork._();

  static const fallback = Color(0xFF342333);
  static final Map<String, Future<Color>> _tones = {};
  // Palette extraction resizes remote posters, but still costs CPU on older
  // notebooks. Never decode unlimited covers in parallel.
  static const int _maxPaletteJobs = 2;
  static int _activePaletteJobs = 0;
  static final Queue<Completer<void>> _paletteQueue =
      Queue<Completer<void>>();

  static Future<void> _acquirePaletteSlot() async {
    if (_activePaletteJobs < _maxPaletteJobs) {
      _activePaletteJobs++;
      return;
    }
    final waiting = Completer<void>();
    _paletteQueue.add(waiting);
    await waiting.future;
  }

  static void _releasePaletteSlot() {
    if (_paletteQueue.isNotEmpty) {
      // A waiting job takes ownership of the released slot.
      _paletteQueue.removeFirst().complete();
    } else {
      _activePaletteJobs--;
    }
  }

  /// Upgrade known, immutable asset URLs without guessing an image/edition.
  static String bestUrl(String original, {double devicePixels = 0, bool panorama = false}) {
    final uri = Uri.tryParse(original);
    if (uri == null || uri.scheme != 'https') return original;
    if (uri.host == 'image.tmdb.org' ||
        uri.host == 'img.amodb.dev') {
      final parts = uri.pathSegments.toList();
      if (parts.length >= 4 && parts[0] == 't' && parts[1] == 'p') {
        const candidates = {
          'w92', 'w154', 'w185', 'w300', 'w342', 'w500', 'w780', 'w1280',
        };
        if (candidates.contains(parts[2])) {
          // Panorama and poster use distinct TMDB size ladders. A w1280
          // panorama is sharper than w780; posters remain on valid w780.
          parts[2] = panorama
              ? (devicePixels >= 960 ? 'w1280' : 'w780')
              : (devicePixels >= 540 ? 'w780'
                  : devicePixels >= 300 ? 'w500' : 'w342');
          return uri.replace(pathSegments: parts).toString();
        }
      }
    }
    if (uri.host == 'static.tvmaze.com' && devicePixels >= 340 &&
        uri.path.contains('/medium_portrait/')) {
      return uri.replace(
        path: uri.path.replaceFirst(
          '/medium_portrait/', '/original_untouched/'),
      ).toString();
    }
    if (uri.host == 'covers.openlibrary.org' &&
        devicePixels >= 360 &&
        RegExp(r'-M[.]jpg$', caseSensitive: false).hasMatch(uri.path)) {
      return uri.replace(path: uri.path.replaceFirst(
        RegExp(r'-M[.]jpg$', caseSensitive: false), '-L.jpg')).toString();
    }
    return original;
  }

  /// Dominant color is extracted from the actual cover, never from a title
  /// hash. Flutter scales samples to a small image for bounded CPU use.
  /// Failures (network/CORS/unsupported media) safely retain SATURN burgundy.
  static Future<Color> toneFor(String artworkUrl) {
    if (!artworkUrl.startsWith('https://')) {
      return Future.value(fallback);
    }
    if (_tones.length >= 140 && !_tones.containsKey(artworkUrl)) {
      _tones.remove(_tones.keys.first);
    }
    return _tones.putIfAbsent(artworkUrl, () async {
      await _acquirePaletteSlot();
      try {
        final colors = await ColorScheme.fromImageProvider(
          provider: ResizeImage(
            NetworkImage(artworkUrl),
            width: 56,
          ),
          brightness: Brightness.dark,
        );
        return Color.lerp(fallback, colors.primary, .52) ?? fallback;
      } catch (_) {
        return fallback;
      } finally {
        _releasePaletteSlot();
      }
    });
  }
}
