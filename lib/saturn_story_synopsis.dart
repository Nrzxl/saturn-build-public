import 'package:flutter/material.dart';
import 'saturn_premium_details.dart';

/// Same compact synopsis for TMDB, TVmaze and other video catalogs.
/// Preserves original source text, but never lets a long imported summary
/// take over the entire detail sheet without explicit user action.
class SaturnStorySynopsis extends StatefulWidget {
  const SaturnStorySynopsis({
    super.key, required this.description,
  });

  final String description;

  @override
  State<SaturnStorySynopsis> createState() => _SaturnStorySynopsisState();
}

class _SaturnStorySynopsisState extends State<SaturnStorySynopsis> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant SaturnStorySynopsis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.description.trim();
    final hasLongText = description.length > 220;
    return SaturnDetailSection(
      title: 'A história',
      icon: Icons.auto_stories_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description.isEmpty ? 'Sinopse ainda não disponível.' : description,
            maxLines: hasLongText && !_expanded ? 4 : null,
            overflow: hasLongText && !_expanded
                ? TextOverflow.ellipsis : TextOverflow.visible,
            style: const TextStyle(
              color: satinIvory, height: 1.5, fontSize: 12.5),
          ),
          if (hasLongText) ...[
            const SizedBox(height: 5),
            TextButton.icon(
              key: const Key('saturn-story-synopsis-toggle'),
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4)),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 17),
              label: Text(_expanded ? 'Recolher sinopse' : 'Ler sinopse'),
            ),
          ],
        ],
      ),
    );
  }
}
