import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../providers/pending_logbook_reviews_provider.dart';
import '../widgets/request_changes_dialog.dart';

/// The lecturer's review queue: every logbook entry waiting on them, shown
/// in full, oldest first, with approve and request-changes actions.
class LecturerLogbookReviewScreen extends ConsumerStatefulWidget {
  /// Creates the lecturer logbook review screen.
  const LecturerLogbookReviewScreen({super.key});

  @override
  ConsumerState<LecturerLogbookReviewScreen> createState() =>
      _LecturerLogbookReviewScreenState();
}

class _LecturerLogbookReviewScreenState
    extends ConsumerState<LecturerLogbookReviewScreen> {
  final _processingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final reviewsValue = ref.watch(pendingLogbookReviewsProvider);

    return reviewsValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Entries couldn’t be loaded. Check your connection and try '
            'again.',
        onRetry: () => ref.invalidate(pendingLogbookReviewsProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const AppEmptyState(
            icon: Icons.task_alt_rounded,
            tone: AppTone.blush,
            title: 'Nothing to review',
            message:
                'When your students submit logbook entries, they’ll wait for '
                'you here.',
          );
        }
        // Oldest first: the entry that's waited longest is reviewed first.
        final ordered = [...entries]..sort((a, b) => a.date.compareTo(b.date));

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingLogbookReviewsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                '${Formatters.count(entries.length, 'entry', 'entries')} waiting, '
                'oldest first',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < ordered.length; i++) ...[
                FadeSlideIn(
                  index: i,
                  child: _ReviewCard(
                    entry: ordered[i],
                    isProcessing: _processingIds.contains(ordered[i].entryId),
                    onApprove: () => _approve(ordered[i]),
                    onRequestChanges: () => _requestChanges(ordered[i]),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _approve(LogbookEntryModel entry) async {
    setState(() => _processingIds.add(entry.entryId));
    final result = await ref
        .read(pendingLogbookReviewsProvider.notifier)
        .approve(entry);
    if (!mounted) {
      return;
    }
    setState(() => _processingIds.remove(entry.entryId));
    _showResult(result, successMessage: 'Entry approved.');
  }

  Future<void> _requestChanges(LogbookEntryModel entry) async {
    final comments = await showDialog<String>(
      context: context,
      builder: (_) => const RequestChangesDialog(),
    );
    if (comments == null || !mounted) {
      return;
    }
    setState(() => _processingIds.add(entry.entryId));
    final result = await ref
        .read(pendingLogbookReviewsProvider.notifier)
        .requestChanges(entry: entry, comments: comments);
    if (!mounted) {
      return;
    }
    setState(() => _processingIds.remove(entry.entryId));
    _showResult(result, successMessage: 'Changes requested.');
  }

  void _showResult(Result<void> result, {required String successMessage}) {
    final message = switch (result) {
      Success<void>() => successMessage,
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.entry,
    required this.isProcessing,
    required this.onApprove,
    required this.onRequestChanges,
  });

  final LogbookEntryModel entry;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hours = entry.hoursWorked;
    final hoursText = hours == hours.roundToDouble()
        ? '${hours.round()}'
        : hours.toStringAsFixed(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(name: entry.studentName, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.studentName, style: textTheme.titleMedium),
                    Text(
                      '${Formatters.day(entry.date)} · $hoursText h',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const AppStatusChip(label: 'Waiting', tone: AppTone.blush),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(label: 'Activities', text: entry.activities),
          _Field(label: 'Skills learned', text: entry.skillsLearned),
          _Field(label: 'Challenges', text: entry.challenges),
          _Field(label: 'Solutions applied', text: entry.solutionsApplied),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Request changes',
                  variant: AppButtonVariant.secondary,
                  onPressed: isProcessing ? null : onRequestChanges,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  isLoading: isProcessing,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            text.trim().isEmpty ? '—' : text,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
