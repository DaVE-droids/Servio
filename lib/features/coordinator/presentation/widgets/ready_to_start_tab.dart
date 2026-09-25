import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/utils/formatters.dart';
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
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Placements couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.invalidate(readyToStartProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            icon: Icons.play_circle_outline,
            tone: AppTone.sky,
            title: 'Nothing waiting to start',
            message:
                'Placements with a lecturer assigned wait here until you start '
                'the internship.',
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
      Success<void>() => 'Internship started. The student can now check in.',
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
    final startsIn = internship.startDate
        .toUtc()
        .difference(Formatters.todayUtc())
        .inDays;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlacementCardHeader(
            internship: internship,
            chip: AppStatusChip(
              label: startsIn > 0
                  ? 'Starts in ${Formatters.count(startsIn, 'day')}'
                  : 'Start date reached',
              tone: startsIn > 0 ? AppTone.sky : AppTone.warning,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Supervised by ${internship.lecturerName ?? 'an unnamed lecturer'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Start internship',
            icon: Icons.play_arrow_rounded,
            isLoading: isProcessing,
            onPressed: onActivate,
          ),
        ],
      ),
    );
  }
}
