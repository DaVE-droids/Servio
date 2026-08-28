import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../providers/pending_logbook_reviews_provider.dart';
import '../widgets/request_changes_dialog.dart';

/// Lecturer screen listing logbook entries awaiting review.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Logbook Reviews')),
      body: reviewsValue.when(
        loading: () => const AppLoading(message: 'Loading entries...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load logbook entries. Please try again.',
          onRetry: () => ref.invalidate(pendingLogbookReviewsProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const AppEmptyState(
              title: 'Nothing to Review',
              message: 'Submitted entries from your assigned students will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingLogbookReviewsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _ReviewCard(
                  entry: entry,
                  isProcessing: _processingIds.contains(entry.entryId),
                  onApprove: () => _approve(entry),
                  onRequestChanges: () => _requestChanges(entry),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _approve(LogbookEntryModel entry) async {
    setState(() => _processingIds.add(entry.entryId));

    final result = await ref
        .read(pendingLogbookReviewsProvider.notifier)
        .approve(entry.entryId);

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
        .requestChanges(entryId: entry.entryId, comments: comments);

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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.studentName, style: textTheme.titleMedium),
              ),
              const AppStatusChip(
                label: 'Pending Review',
                type: AppStatusChipType.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(_formatDate(entry.date), style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Activities: ${entry.activities}', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text('Hours worked: ${entry.hoursWorked}', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Request Changes',
                  variant: AppButtonVariant.secondary,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onRequestChanges,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
