import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../providers/pending_internships_provider.dart';

/// Coordinator dashboard tab listing placements awaiting review, with
/// approve/reject actions.
class PendingReviewTab extends ConsumerStatefulWidget {
  /// Creates the pending review tab.
  const PendingReviewTab({super.key});

  @override
  ConsumerState<PendingReviewTab> createState() => _PendingReviewTabState();
}

class _PendingReviewTabState extends ConsumerState<PendingReviewTab> {
  final _processingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final pendingInternshipsAsync = ref.watch(pendingInternshipsProvider);
    final sessionValue = ref.watch(authSessionProvider);
    final coordinatorId = switch (sessionValue) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };

    return pendingInternshipsAsync.when(
      loading: () => const AppLoading(message: 'Loading placements...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load pending placements. Please try again.',
        onRetry: () => ref.invalidate(pendingInternshipsProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            title: 'No Pending Placements',
            message:
                'All caught up! New placement submissions will appear here for review.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingInternshipsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: internships.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final internship = internships[index];
              return _PendingInternshipCard(
                internship: internship,
                isProcessing: _processingIds.contains(internship.internshipId),
                onApprove: coordinatorId == null
                    ? null
                    : () => _approve(internship, coordinatorId),
                onReject: coordinatorId == null
                    ? null
                    : () => _confirmReject(internship, coordinatorId),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _approve(InternshipModel internship, String coordinatorId) {
    return _runAction(
      internship.internshipId,
      () => ref
          .read(pendingInternshipsProvider.notifier)
          .approve(internship, coordinatorId),
      successMessage: 'Placement approved.',
    );
  }

  Future<void> _confirmReject(
    InternshipModel internship,
    String coordinatorId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Reject Placement?',
        message:
            'This will reject the placement submitted for ${internship.companyName}. This cannot be undone.',
        confirmLabel: 'Reject',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      internship.internshipId,
      () => ref
          .read(pendingInternshipsProvider.notifier)
          .reject(internship, coordinatorId),
      successMessage: 'Placement rejected.',
    );
  }

  Future<void> _runAction(
    String internshipId,
    Future<Result<void>> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _processingIds.add(internshipId));

    final result = await action();

    if (!mounted) {
      return;
    }
    setState(() => _processingIds.remove(internshipId));

    final message = switch (result) {
      Success<void>() => successMessage,
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PendingInternshipCard extends StatelessWidget {
  const _PendingInternshipCard({
    required this.internship,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final InternshipModel internship;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

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
                child: Text(
                  internship.companyName,
                  style: textTheme.titleMedium,
                ),
              ),
              const AppStatusChip(
                label: 'Pending Review',
                type: AppStatusChipType.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${internship.department} • ${internship.state}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _studentLabel(internship),
            style: textTheme.bodySmall,
          ),
          Text(
            'Submitted ${formatShortDate(internship.submittedAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.destructive,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onReject,
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

/// Formats a date as `d/M/yyyy` in the viewer's local timezone.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

/// Shows the student's name, falling back to their matric number and then
/// their raw ID for placements submitted before the name was denormalized
/// onto `internships`.
String _studentLabel(InternshipModel internship) {
  if (internship.studentName.isNotEmpty) {
    final matric = internship.studentMatricNumber;
    return matric.isEmpty
        ? internship.studentName
        : '${internship.studentName} • $matric';
  }
  if (internship.studentMatricNumber.isNotEmpty) {
    return internship.studentMatricNumber;
  }
  return 'Student ${internship.studentId}';
}
