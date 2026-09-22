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
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../providers/ready_to_start_provider.dart';
import 'coordinator_ui.dart';
import 'pending_review_tab.dart' show formatShortDate;

/// Coordinator dashboard tab listing placements with a lecturer assigned
/// but not yet activated.
class ReadyToStartTab extends ConsumerStatefulWidget {
  /// Creates the ready-to-start tab.
  const ReadyToStartTab({super.key});

  @override
  ConsumerState<ReadyToStartTab> createState() => _ReadyToStartTabState();
}

class _ReadyToStartTabState extends ConsumerState<ReadyToStartTab> {
  final _processingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final readyToStartValue = ref.watch(readyToStartProvider);
    final coordinatorId = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };

    return readyToStartValue.when(
      loading: () => const AppLoading(message: 'Loading placements...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load placements. Please try again.',
        onRetry: () => ref.invalidate(readyToStartProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            title: 'Nothing Waiting to Start',
            message:
                'Placements with a lecturer assigned will appear here until activated.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(readyToStartProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: internships.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final internship = internships[index];
              return _ReadyToStartCard(
                internship: internship,
                isProcessing: _processingIds.contains(internship.internshipId),
                onActivate: coordinatorId == null
                    ? null
                    : () => _activate(internship, coordinatorId),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _activate(
    InternshipModel internship,
    String coordinatorId,
  ) async {
    setState(() => _processingIds.add(internship.internshipId));

    final result = await ref
        .read(readyToStartProvider.notifier)
        .activate(internship, coordinatorId);

    if (!mounted) {
      return;
    }
    setState(() => _processingIds.remove(internship.internshipId));

    final message = switch (result) {
      Success<void>() => 'Internship activated.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadyToStartCard extends StatelessWidget {
  const _ReadyToStartCard({
    required this.internship,
    required this.isProcessing,
    required this.onActivate,
  });

  final InternshipModel internship;
  final bool isProcessing;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlacementCardHeader(
            internship: internship,
            chip: const AppStatusChip(
              label: 'Assigned',
              type: AppStatusChipType.info,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Lecturer: ${internship.lecturerName ?? 'Name not recorded'}',
            style: textTheme.bodySmall,
          ),
          if (internship.assignedAt != null)
            Text(
              'Assigned ${formatShortDate(internship.assignedAt!)}',
              style: textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Activate',
            isLoading: isProcessing,
            onPressed: isProcessing ? null : onActivate,
          ),
        ],
      ),
    );
  }
}
