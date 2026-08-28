import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/dashboard_summary_card.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/assigned_students_provider.dart';

/// Lecturer dashboard: assigned-student summary and quick access.
class LecturerDashboardScreen extends ConsumerWidget {
  /// Creates the lecturer dashboard screen.
  const LecturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(profileControllerProvider);
    final assignedStudentsValue = ref.watch(assignedStudentsProvider);
    final authState = ref.watch(authenticationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        actions: [
          TextButton(
            onPressed: authState.isLoading
                ? null
                : () => ref
                      .read(authenticationControllerProvider.notifier)
                      .logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: profileValue.when(
        loading: () => const AppLoading(message: 'Loading dashboard...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load your dashboard. Please try again.',
          onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profileState) {
          final user = profileState.user;
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(profileControllerProvider.notifier).refresh();
              ref.invalidate(assignedStudentsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  user == null ? 'Hello' : 'Hello, ${user.firstName}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (user != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    user.department,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _assignedStudentsCard(context, assignedStudentsValue),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Access',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Keep your profile current so coordinators and students see accurate information.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Open Profile',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.push(AppRoutes.profile),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _assignedStudentsCard(
    BuildContext context,
    AsyncValue<List<InternshipModel>> assignedStudentsValue,
  ) {
    return assignedStudentsValue.when(
      loading: () => const DashboardSummaryCard(
        title: 'Assigned Students',
        value: 'Loading...',
        description: 'Checking your assigned placements.',
        icon: Icons.groups_outlined,
        color: AppColors.information,
      ),
      error: (error, stackTrace) => const DashboardSummaryCard(
        title: 'Assigned Students',
        value: 'Unavailable',
        description: 'Unable to load your assigned students right now.',
        icon: Icons.groups_outlined,
        color: AppColors.error,
      ),
      data: (internships) => DashboardSummaryCard(
        title: 'Assigned Students',
        value: '${internships.length}',
        description: internships.isEmpty
            ? 'No students assigned to you yet.'
            : 'Students currently under your supervision.',
        icon: Icons.groups_outlined,
        color: internships.isEmpty ? AppColors.secondary : AppColors.success,
        actionLabel: internships.isEmpty ? null : 'View Students',
        onActionPressed: internships.isEmpty
            ? null
            : () => context.push(AppRoutes.assignedStudents),
      ),
    );
  }
}
