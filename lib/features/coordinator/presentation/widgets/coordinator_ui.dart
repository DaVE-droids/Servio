import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../reports/data/models/internship_progress.dart';

export '../../../../core/widgets/info_row.dart';
export '../../../../core/widgets/placement_status_chip.dart';
export '../../../../core/widgets/section_header.dart';

/// Small building blocks shared by the coordinator Students, Lecturers,
/// and Reports screens, so the three read the same way.

/// One-line progress summary: attendance days, logbook, visits.
class ProgressLine extends StatelessWidget {
  /// Creates a progress line.
  const ProgressLine(this.progress, {super.key});

  /// The counts to show.
  final InternshipProgress progress;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      children: [
        _stat(
          Icons.fact_check_outlined,
          '${progress.attendanceDays} day${progress.attendanceDays == 1 ? '' : 's'}',
          style,
        ),
        _stat(
          Icons.menu_book_outlined,
          '${progress.logbookApproved}/${progress.logbookEntries} logbook approved',
          style,
        ),
        _stat(
          Icons.person_search_outlined,
          '${progress.visits} visit${progress.visits == 1 ? '' : 's'}',
          style,
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String text, TextStyle? style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}

/// `2026-09-14` style date, matching the rest of the coordinator screens.
String shortDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// The top of every placement card on the coordinator's Placements tabs:
/// who the student is, then where and when they'll work.
///
/// Leads with the student rather than the company because the coordinator
/// is deciding about a *person* — and two students can share an employer.
/// Never falls back to showing a raw database ID.
class PlacementCardHeader extends StatelessWidget {
  /// Creates a placement card header.
  const PlacementCardHeader({
    required this.internship,
    required this.chip,
    this.showDetails = false,
    super.key,
  });

  /// The placement being shown.
  final InternshipModel internship;

  /// Status chip shown beside the name.
  final Widget chip;

  /// Also show supervisor, dates, and address — what a coordinator needs
  /// in front of them to approve a placement.
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = internship.studentName.trim().isEmpty
        ? 'Unnamed student'
        : internship.studentName;
    final identity = [
      if (internship.studentMatricNumber.isNotEmpty)
        internship.studentMatricNumber,
      internship.department,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppAvatar(name: name, size: 44),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    identity,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            chip,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Fact(
          icon: Icons.apartment_outlined,
          text: [
            internship.companyName,
            if (internship.state.isNotEmpty) internship.state,
          ].join(' · '),
        ),
        if (showDetails) ...[
          _Fact(icon: Icons.place_outlined, text: internship.companyAddress),
          _Fact(
            icon: Icons.badge_outlined,
            text:
                '${internship.companySupervisorName} · '
                '${internship.companySupervisorPhone}',
          ),
          _Fact(
            icon: Icons.date_range_outlined,
            text: Formatters.dateRange(
              internship.startDate,
              internship.endDate,
            ),
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
