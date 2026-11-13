import 'package:flutter/material.dart';

import 'saturn_personal_score.dart';
import 'saturn_review_tiers.dart';

/// Displays every real score linked to this exact catalogue ID. A partner's
/// rating is not restricted to sharedOps / Nossa Órbita membership: both
/// people can rate the same film before adding it to a shared collection.
///
/// All poster sizes use the original SATURN horizontal, outlined score
/// pills. Scale the paired badges together on narrow cards without stacking
/// them. Ratings are read from their own profile; nothing is invented or saved.
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

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        key: Key('saturn-horizontal-scores-$workId'),
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
  }
}
