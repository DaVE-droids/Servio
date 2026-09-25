import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/approved_internships_provider.dart';
import '../providers/pending_internships_provider.dart';
import '../providers/ready_to_start_provider.dart';
import '../widgets/needs_lecturer_tab.dart';
import '../widgets/pending_review_tab.dart';
import '../widgets/ready_to_start_tab.dart';

/// The coordinator's Placements section, laid out as the pipeline every
/// placement moves through before it starts: waiting for review, waiting
/// for a lecturer, waiting to begin. Each stage shows how many are in it,
/// so the busiest queue is obvious at a glance.
class CoordinatorDashboardScreen extends ConsumerStatefulWidget {
  /// Creates the coordinator dashboard screen.
  const CoordinatorDashboardScreen({super.key});

  @override
  ConsumerState<CoordinatorDashboardScreen> createState() =>
      _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState
    extends ConsumerState<CoordinatorDashboardScreen> {
  var _stage = 0;

  @override
  Widget build(BuildContext context) {
    final counts = [
      ref.watch(pendingInternshipsProvider).value?.length,
      ref.watch(approvedInternshipsProvider).value?.length,
      ref.watch(readyToStartProvider).value?.length,
    ];
    const stages = [
      (
        'Pending review',
        'Approve or reject',
        Icons.inbox_outlined,
        AppTone.warning,
      ),
      (
        'Needs a lecturer',
        'Assign a supervisor',
        Icons.person_add_alt_outlined,
        AppTone.blush,
      ),
      (
        'Ready to start',
        'Start the internship',
        Icons.play_circle_outline,
        AppTone.sky,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StageTile(
                    label: stages[i].$1,
                    hint: stages[i].$2,
                    icon: stages[i].$3,
                    tone: stages[i].$4,
                    count: counts[i],
                    isSelected: _stage == i,
                    onTap: () => setState(() => _stage = i),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_stage) {
              0 => const PendingReviewTab(key: ValueKey(0)),
              1 => const NeedsLecturerTab(key: ValueKey(1)),
              _ => const ReadyToStartTab(key: ValueKey(2)),
            },
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.label,
    required this.hint,
    required this.icon,
    required this.tone,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final AppTone tone;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$label, ${count ?? 'loading'}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.tile),
          side: BorderSide(
            color: isSelected ? AppColors.ink : AppColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 10 : AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      count == null ? '–' : '$count',
                      style: textTheme.headlineMedium?.copyWith(
                        fontFeatures: AppTypography.tabular,
                        color: AppColors.inkDeep,
                      ),
                    ),
                    const Spacer(),
                    if (!isCompact)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tone.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 17, color: tone.foreground),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                if (!isCompact) Text(hint, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
