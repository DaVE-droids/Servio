import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../reports/data/models/internship_progress.dart';

/// Small building blocks shared by the coordinator Students, Lecturers,
/// and Reports screens, so the three read the same way.

/// Coloured chip for a student's placement status; `null` means the student
/// hasn't submitted a placement at all.
class PlacementStatusChip extends StatelessWidget {
  /// Creates a placement status chip.
  const PlacementStatusChip({required this.status, super.key});

  /// The placement status, or null for "no placement".
  final InternshipStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, type) = placementStatusLabel(status);
    return AppStatusChip(label: label, type: type);
  }
}

/// Human label and chip colour for a placement status.
(String, AppStatusChipType) placementStatusLabel(InternshipStatus? status) {
  return switch (status) {
    null => ('No placement', AppStatusChipType.neutral),
    InternshipStatus.draft => ('Draft', AppStatusChipType.neutral),
    InternshipStatus.pendingReview => ('Pending review', AppStatusChipType.warning),
    InternshipStatus.approved => ('Needs lecturer', AppStatusChipType.warning),
    InternshipStatus.rejected => ('Rejected', AppStatusChipType.error),
    InternshipStatus.assigned => ('Ready to start', AppStatusChipType.info),
    InternshipStatus.active => ('Active', AppStatusChipType.success),
    InternshipStatus.completed => ('Completed', AppStatusChipType.success),
    InternshipStatus.archived => ('Archived', AppStatusChipType.neutral),
  };
}

/// Bold heading that separates groups within a screen.
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader(this.title, {super.key});

  /// Heading text.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A "Label: value" line, with the label in a fixed-width column so
/// stacked rows line up.
class InfoRow extends StatelessWidget {
  /// Creates an info row.
  const InfoRow(this.label, this.value, {super.key});

  /// Left-hand label.
  final String label;

  /// Right-hand value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: textTheme.bodySmall)),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

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
/// the student's name as the bold title, then who they are, then where.
///
/// Leads with the student rather than the company because the coordinator
/// is deciding about a *person* — and two students can share an employer.
/// Never falls back to showing a raw database ID.
class PlacementCardHeader extends StatelessWidget {
  /// Creates a placement card header.
  const PlacementCardHeader({
    required this.internship,
    required this.chip,
    super.key,
  });

  /// The placement being shown.
  final InternshipModel internship;

  /// Status chip shown beside the name.
  final Widget chip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = internship.studentName.trim().isEmpty
        ? 'Unnamed student'
        : internship.studentName;
    final identity = [
      if (internship.studentMatricNumber.isNotEmpty) internship.studentMatricNumber,
      internship.department,
    ].join(' · ');
    final location = [
      internship.companyName,
      if (internship.state.isNotEmpty) internship.state,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            chip,
          ],
        ),
        Text(identity, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(location, style: textTheme.bodyMedium),
      ],
    );
  }
}
