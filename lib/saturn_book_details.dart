import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'saturn_premium_details.dart';

class OpenLibraryWorkDetails {
  const OpenLibraryWorkDetails({
    required this.description,
    required this.coverUrl,
    this.averageRating,
    this.ratingCount,
  });

  final String description;
  final String coverUrl;
  final double? averageRating;
  final int? ratingCount;
}

/// Book work metadata is loaded only when a user opens a book; this is
/// compatible with Open Library's human-centred API usage guidelines.
class SaturnBookDetailsService {
  SaturnBookDetailsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static final Map<String, Future<OpenLibraryWorkDetails?>> _cache = {};

  Future<OpenLibraryWorkDetails?> fetch(String workId) {
    final match = RegExp(r'^openlibrary:/works/(OL[0-9]+W)$').firstMatch(workId);
    if (match == null) return Future.value(null);
    final id = match.group(1)!;
    return _cache.putIfAbsent(id, () async {
      try {
        final request = Uri.https('openlibrary.org', '/works/$id.json');
        final response = await _client.get(request, headers: const {
          'Accept': 'application/json',
          'User-Agent': 'SATURNMobile/0.7 (private book discovery)',
        }).timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          _cache.remove(id);
          return null;
        }
        final document = jsonDecode(utf8.decode(response.bodyBytes));
        if (document is! Map) return null;
        final descRaw = document['description'];
        final description = descRaw is String
            ? descRaw
            : descRaw is Map
                ? (descRaw['value'] ?? '').toString()
                : '';
        final covers = document['covers'];
        final coverId = covers is List && covers.isNotEmpty
            ? covers.first
            : null;
        final coverUrl = coverId is num && coverId > 0
            ? 'https://covers.openlibrary.org/b/id/${coverId.toInt()}-L.jpg'
            : '';
        double? average;
        int? count;
        try {
          final ratings = await _client.get(
            Uri.https('openlibrary.org', '/works/$id/ratings.json'),
            headers: const {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 6));
          if (ratings.statusCode == 200) {
            final data = jsonDecode(utf8.decode(ratings.bodyBytes));
            if (data is Map && data['summary'] is Map) {
              final summary = data['summary'] as Map;
              final score = summary['average'];
              if (score is num && score >= 0 && score <= 5) {
                average = score.toDouble();
              }
              final n = summary['count'];
              if (n is num && n >= 0) count = n.toInt();
            }
          }
        } catch (_) {
          // A failed rating request cannot hide the real synopsis.
        }
        return OpenLibraryWorkDetails(
          description: description.trim(),
          coverUrl: coverUrl,
          averageRating: average,
          ratingCount: count,
        );
      } catch (_) {
        _cache.remove(id);
        return null;
      }
    });
  }

  void close() => _client.close();
}

class SaturnBookDetailsPanel extends StatefulWidget {
  const SaturnBookDetailsPanel({
    super.key,
    required this.bookId,
    required this.fallbackDescription,
    required this.fallbackCover,
  });
  final String bookId;
  final String fallbackDescription;
  final String fallbackCover;

  @override
  State<SaturnBookDetailsPanel> createState() => _SaturnBookDetailsPanelState();
}

class _SaturnBookDetailsPanelState extends State<SaturnBookDetailsPanel> {
  late final SaturnBookDetailsService _service;
  late Future<OpenLibraryWorkDetails?> _future;

  @override
  void initState() {
    super.initState();
    _service = SaturnBookDetailsService();
    _future = _service.fetch(widget.bookId);
  }

  @override
  void didUpdateWidget(covariant SaturnBookDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _future = _service.fetch(widget.bookId);
    }
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenLibraryWorkDetails?>(
      future: _future,
      builder: (context, snapshot) {
        final details = snapshot.data;
        final description = details?.description.isNotEmpty == true
            ? details!.description
            : widget.fallbackDescription;
        final cover = details?.coverUrl.isNotEmpty == true
            ? details!.coverUrl
            : widget.fallbackCover;
        return SaturnDetailSection(
          title: 'Sobre o livro',
          icon: Icons.auto_stories_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(
                  minHeight: 2, color: satinGold),
              const SizedBox(height: 7),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (cover.isNotEmpty)
                  Container(
                    width: 106,
                    height: 160,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 12, offset: Offset(0, 5)),
                      ],
                    ),
                    child: Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.menu_book,
                          color: satinGold, size: 45),
                    ),
                  ),
                if (cover.isNotEmpty) const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    description.trim().isEmpty
                        ? 'A sinopse completa não está disponível '
                          'nesta fonte para esta edição.'
                        : description,
                    maxLines: 24,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.55, color: satinIvory,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]),
              if (details?.averageRating != null) ...[
                const SizedBox(height: 13),
                Text(
                  'Comunidade Open Library: '
                  '${details!.averageRating!.toStringAsFixed(1)} / 5 '
                  '★  (${details.ratingCount ?? 0} avaliações)',
                  style: const TextStyle(
                    color: satinGold, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Sinopse, arte e avaliação fornecidas pela Open Library. '
                'As estrelas do SATURN são independentes.',
                style: TextStyle(
                  color: satinSubdued, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
