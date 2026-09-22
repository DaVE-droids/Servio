import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Coordinator lecturer management (PRD §18 "Lecturer management"):
/// approve lecturers who signed up, and see each approved lecturer's
/// current workload.
///
/// Rendered inside the coordinator app shell, which supplies the scaffold.
class CoordinatorLecturersScreen extends ConsumerStatefulWidget {
  /// Creates the lecturers screen.
  const CoordinatorLecturersScreen({super.key});

  @override
  ConsumerState<CoordinatorLecturersScreen> createState() =>
      _CoordinatorLecturersScreenState();
}

class _CoordinatorLecturersScreenState
    extends ConsumerState<CoordinatorLecturersScreen> {
  final _approvingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return overviewValue.when(
      loading: () => const AppLoading(message: 'Loading lecturers...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load lecturers. Please try again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.lecturers.isEmpty) {
          return const AppEmptyState(
            title: 'No Lecturers Yet',
            message:
                'Lecturers appear here after they sign up. Approve them to '
                'start assigning students.',
          );
        }

        final pending = overview.pendingLecturers;
        final active = overview.activeLecturers;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (pending.isNotEmpty) ...[
                SectionHeader('Awaiting approval (${pending.length})'),
                for (final lecturer in pending) ...[
                  _PendingLecturerCard(
                    lecturer: lecturer,
                    isApproving: _approvingIds.contains(lecturer.uid),
                    onApprove: () => _approve(lecturer),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              SectionHeader('Lecturers (${active.length})'),
              if (active.isEmpty)
                const Text('No approved lecturers yet.')
              else
                for (final lecturer in active) ...[
                  _LecturerCard(overview: overview, lecturer: lecturer),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _approve(UserModel lecturer) async {
    setState(() => _approvingIds.add(lecturer.uid));
    final result = await ref
        .read(coordinatorActionsProvider)
        .setLecturerActive(lecturer, isActive: true);
    if (!mounted) {
      return;
    }
    setState(() => _approvingIds.remove(lecturer.uid));
    final message = switch (result) {
      Success<void>() => '${lecturer.firstName} ${lecturer.lastName} approved.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PendingLecturerCard extends StatelessWidget {
  const _PendingLecturerCard({
    required this.lecturer,
    required this.isApproving,
    required this.onApprove,
  });

  final UserModel lecturer;
  final bool isApproving;
  final VoidCallback onApprove;

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
                  '${lecturer.firstName} ${lecturer.lastName}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppStatusChip(
                label: 'Pending',
                type: AppStatusChipType.warning,
              ),
            ],
          ),
          Text(
            [
              if ((lecturer.staffId ?? '').isNotEmpty) lecturer.staffId!,
              lecturer.department,
            ].join(' · '),
            style: textTheme.bodySmall,
          ),
          Text(lecturer.email, style: textTheme.bodySmall),
          Text(
            'Signed up ${shortDate(lecturer.createdAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Approve',
            isLoading: isApproving,
            onPressed: onApprove,
          ),
        ],
      ),
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({required this.overview, required this.lecturer});

  final CoordinatorOverview overview;
  final UserModel lecturer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final load = overview.activeLoadFor(lecturer.uid);
    final visits = overview
        .allSupervisedBy(lecturer.uid)
        .fold<int>(
          0,
          (sum, internship) =>
              sum + overview.progressFor(internship.internshipId).visits,
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.coordinatorLecturerDetail(lecturer.uid)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lecturer.firstName} ${lecturer.lastName}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(lecturer.department, style: textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${load.length} current student${load.length == 1 ? '' : 's'}'
                      ' · $visits visit${visits == 1 ? '' : 's'} recorded',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
