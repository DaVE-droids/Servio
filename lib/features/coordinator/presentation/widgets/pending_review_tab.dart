import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/utils/formatters.dart';
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
import 'coordinator_ui.dart';

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
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Placements couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.invalidate(pendingInternshipsProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inbox_outlined,
            tone: AppTone.warning,
            title: 'Nothing waiting for review',
            message:
                'New placements that students submit will wait here for your '
                'decision.',
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
        title: 'Reject this placement?',
        message:
            '${internship.studentName}’s placement at ${internship.companyName} '
            'will be rejected and they’ll be notified to submit a new one. '
            'This can’t be undone.',
        confirmLabel: 'Reject placement',
        isDestructive: true,
        icon: Icons.block_rounded,
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlacementCardHeader(
            internship: internship,
            showDetails: true,
            chip: AppStatusChip(
              label: 'Submitted ${Formatters.relative(internship.submittedAt)}',
              tone: AppTone.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.secondary,
                  onPressed: isProcessing ? null : onReject,
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
