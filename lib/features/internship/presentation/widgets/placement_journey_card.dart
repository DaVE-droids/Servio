import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/journey_track.dart';
import '../../../../core/widgets/placement_status_chip.dart';
import '../../data/models/internship_model.dart';

/// The student's placement at a glance: where it is on the journey, and in
/// one plain sentence, what happens next and who it's waiting on.
class PlacementJourneyCard extends StatelessWidget {
  /// Creates the journey card.
  const PlacementJourneyCard({
    required this.internship,
    this.action,
    super.key,
  });

  /// The student's current placement, or null if none is submitted.
  final InternshipModel? internship;

  /// Optional button under the next step, e.g. "Submit placement".
  final Widget? action;

  /// What happens next for a placement in this state, from the student's
  /// point of view.
  static String nextStepFor(InternshipModel? internship) {
    if (internship == null) {
      return 'Tell us where you’ll be doing your placement. Your coordinator '
          'reviews it before your internship starts.';
    }
    return switch (internship.status) {
      InternshipStatus.draft || InternshipStatus.pendingReview =>
        'Your coordinator is reviewing your placement. You’ll be notified '
            'as soon as there’s a decision.',
      InternshipStatus.approved =>
        'Approved. Next, your coordinator assigns the lecturer who will '
            'supervise you.',
      InternshipStatus.assigned =>
        '${internship.lecturerName ?? 'A lecturer'} will supervise you. Your '
            'coordinator starts the internship when you begin on '
            '${Formatters.date(internship.startDate)}.',
      InternshipStatus.active =>
        'You’re on placement. Check in each working day and write your '
            'logbook entry before you finish.',
      InternshipStatus.completed || InternshipStatus.archived =>
        'Your internship is complete. Your attendance, logbook, and visit '
            'records are kept.',
      InternshipStatus.rejected =>
        'This placement wasn’t approved. Check your notifications for the '
            'reason, then submit a new one.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final placement = internship;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR PLACEMENT', style: textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      placement?.companyName ?? 'Not submitted yet',
                      style: textTheme.headlineSmall,
                    ),
                    if (placement != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          placement.state,
                          Formatters.dateRange(
                            placement.startDate,
                            placement.endDate,
                          ),
                        ].where((part) => part.isNotEmpty).join(' · '),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (placement != null) ...[
                const SizedBox(width: AppSpacing.sm),
                PlacementStatusChip(status: placement.status),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          JourneyTrack(status: placement?.status),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 18,
                    color: AppColors.skyStrong,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    nextStepFor(placement),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
