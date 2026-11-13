import 'package:flutter/material.dart';

import 'saturn_personal_score.dart';
import 'saturn_review_tiers.dart';

/// Displays every real score linked to this exact catalogue ID. A partner's
/// rating is not restricted to sharedOps / Nossa Órbita membership: both
/// people can rate the same film before adding it to a shared collection.
///
/// Narrow poster cards use two readable rows rather than shrinking both
/// full-size pills into illegible text. No rating is invented or written.
class SaturnCardCoupleScores extends StatelessWidget {
  const SaturnCardCoupleScores({
    super.key,
    required this.workId,
    required this.records,
    required this.profileNames,
    required this.viewerProfile,
  });

  final String workId;
  final Map<String, dynamic> records;
  final List<String> profileNames;
  final int viewerProfile;

  List<int> get ratedProfiles => [
    for (var person = 0; person < 2; person++)
      if (SaturnReviewClassification.stars(
          records['$person:$workId']) != null)
        person,
  ];

  @override
  Widget build(BuildContext context) {
    final rated = ratedProfiles;
    if (rated.isEmpty) return const SizedBox.shrink();
    String label(int person) => person == viewerProfile
        ? 'Você'
        : (person < profileNames.length &&
                profileNames[person].trim().isNotEmpty
            ? profileNames[person].trim()
            : 'Outro perfil');

    return LayoutBuilder(builder: (context, constraints) {
      if (rated.length > 1 && constraints.maxWidth < 190) {
        // Two 14px lines fit the library's 34px score slot (which also has
        // vertical padding). Keep one Text per profile for accessibility.
        // Limit very long names rather than clipping the numeric score.
        String compactName(int person) {
          final first = label(person).split(RegExp(r'\\s+')).first;
          return first.length > 10 ? '${first.substring(0, 9)}…' : first;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final person in rated)
              SizedBox(
                height: 14,
                child: Row(
                  key: Key('saturn-library-person-$person-$workId'),
                  children: [
                    Flexible(child: Text(
                      '${compactName(person)} '
                      '${SaturnReviewClassification.stars(
                          records['$person:$workId'])!.toStringAsFixed(1)} ★',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SaturnReviewClassification.fromRating(
                              records['$person:$workId'])?.color ??
                            const Color(0xFFCEB9C6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                  ],
                ),
              ),
          ],
        );
      }

      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final person in rated)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: SaturnPersonalScore(
                  key: Key('saturn-library-person-$person-$workId'),
                  name: label(person),
                  record: records['$person:$workId'],
                ),
              ),
          ],
        ),
      );
    });
  }
}
