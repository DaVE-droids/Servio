import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
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
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Lecturer management (PRD §18): approve lecturers who signed up, and see
/// how many students each approved lecturer supervises.
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
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Lecturers couldn’t be loaded. Check your connection and try '
            'again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.lecturers.isEmpty) {
          return const AppEmptyState(
            icon: Icons.badge_outlined,
            title: 'No lecturers yet',
            message:
                'Lecturers appear here after they sign up. Approve them to '
                'start assigning students.',
          );
        }

        final pending = overview.pendingLecturers;
        final active = overview.activeLecturers;
        final maxLoad = active.isEmpty
            ? 0
            : active
                  .map(
                    (lecturer) => overview.activeLoadFor(lecturer.uid).length,
                  )
                  .reduce((a, b) => a > b ? a : b);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (pending.isNotEmpty) ...[
                SectionCard(
                  title: 'Waiting for your approval',
                  subtitle:
                      'They can sign in, but can’t see any students until you '
                      'approve them.',
                  child: Column(
                    children: [
                      for (var i = 0; i < pending.length; i++) ...[
                        if (i > 0) const Divider(),
                        _PendingLecturerRow(
                          lecturer: pending[i],
                          isApproving: _approvingIds.contains(pending[i].uid),
                          onApprove: () => _approve(pending[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SectionHeader(
                'Approved lecturers',
                trailing: Text(
                  Formatters.count(active.length, 'lecturer'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (active.isEmpty)
                const AppCard(
                  child: AppEmptyState(
                    compact: true,
                    icon: Icons.badge_outlined,
                    title: 'No approved lecturers',
                    message:
                        'Approve a lecturer above to start assigning students.',
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 560
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final lecturer in active)
                          SizedBox(
                            width: width,
                            child: _LecturerCard(
                              overview: overview,
                              lecturer: lecturer,
                              maxLoad: maxLoad,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.xl),
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
      Success<void>() =>
        '${lecturer.firstName} ${lecturer.lastName} approved and notified.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PendingLecturerRow extends StatelessWidget {
  const _PendingLecturerRow({
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
    final name = '${lecturer.firstName} ${lecturer.lastName}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppAvatar(name: name, photoUrl: lecturer.profilePhotoUrl, size: 42),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleSmall),
                Text(
                  [
                    lecturer.department,
                    if ((lecturer.staffId ?? '').isNotEmpty) lecturer.staffId!,
                    lecturer.email,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                Text(
                  'Signed up ${Formatters.relative(lecturer.createdAt)}',
                  style: textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Approve',
            icon: Icons.check_rounded,
            expand: false,
            isLoading: isApproving,
            onPressed: onApprove,
          ),
        ],
      ),
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({
    required this.overview,
    required this.lecturer,
    required this.maxLoad,
  });

  final CoordinatorOverview overview;
  final UserModel lecturer;
  final int maxLoad;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = '${lecturer.firstName} ${lecturer.lastName}';
    final load = overview.activeLoadFor(lecturer.uid);
    final visits = overview
        .allSupervisedBy(lecturer.uid)
        .fold<int>(
          0,
          (sum, internship) =>
              sum + overview.progressFor(internship.internshipId).visits,
        );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      onTap: () =>
          context.push(AppRoutes.coordinatorLecturerDetail(lecturer.uid)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(
                name: name,
                photoUrl: lecturer.profilePhotoUrl,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      lecturer.department,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                Formatters.count(load.length, 'student'),
                style: textTheme.titleSmall,
              ),
              const Spacer(),
              AppStatusChip(
                label: Formatters.count(visits, 'visit'),
                tone: AppTone.ink,
                icon: Icons.person_pin_circle_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Workload relative to the busiest lecturer, so imbalances show.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: maxLoad == 0 ? 0 : load.length / maxLoad,
              minHeight: 6,
              color: AppColors.skyStrong,
              backgroundColor: AppColors.skySoft,
            ),
          ),
        ],
      ),
    );
  }
}
