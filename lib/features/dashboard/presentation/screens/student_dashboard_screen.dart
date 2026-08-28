import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../internship/presentation/controllers/internship_state.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../widgets/student_dashboard_summary_card.dart';

/// Student dashboard showing the current user's placement overview.
class StudentDashboardScreen extends ConsumerWidget {
  /// Creates the student dashboard screen.
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(profileControllerProvider);
    final internshipValue = ref.watch(internshipControllerProvider);

    return profileValue.when(
      loading: () => const AppLoading(message: 'Loading dashboard...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your dashboard. Please try again.',
        onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
      ),
      data: (profileState) {
        final user = profileState.user;
        if (user == null) {
          return AppEmptyState(
            title: 'Dashboard unavailable',
            message:
                profileState.errorMessage ??
                'Your student profile could not be loaded.',
            actionLabel: 'Retry',
            onActionPressed: () =>
                ref.read(profileControllerProvider.notifier).refresh(),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _DashboardHeader(user: user),
              const SizedBox(height: AppSpacing.md),
              _DashboardGrid(internshipValue: internshipValue),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Recent Notifications',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No notifications yet. Important placement, attendance, and logbook updates will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
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
                      'Keep your student profile current so coordinators and lecturers see accurate information.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Open Profile',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.go(AppRoutes.profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.internshipValue});

  final AsyncValue<InternshipState> internshipValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: crossAxisCount == 1 ? 3.1 : 2.2,
          children: [
            _internshipCard(context),
            const StudentDashboardSummaryCard(
              title: "Today's Attendance",
              value: 'Not recorded',
              description:
                  'Check-in and checkout status will appear here after attendance is implemented.',
              icon: Icons.fact_check_outlined,
              color: AppColors.information,
            ),
            const StudentDashboardSummaryCard(
              title: 'Pending Logbook',
              value: 'Coming soon',
              description:
                  'Daily logbook reminders will appear here in the logbook phase.',
              icon: Icons.menu_book_outlined,
              color: AppColors.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _internshipCard(BuildContext context) {
    return internshipValue.when(
      loading: () => const StudentDashboardSummaryCard(
        title: 'Current Internship',
        value: 'Loading...',
        description: 'Checking your submitted placement status.',
        icon: Icons.business_center_outlined,
        color: AppColors.information,
      ),
      error: (error, stackTrace) => const StudentDashboardSummaryCard(
        title: 'Current Internship',
        value: 'Unavailable',
        description: 'Unable to load your placement status right now.',
        icon: Icons.business_center_outlined,
        color: AppColors.error,
      ),
      data: (state) {
        final internship = state.currentInternship;
        if (internship == null) {
          return StudentDashboardSummaryCard(
            title: 'Current Internship',
            value: 'Not submitted yet',
            description:
                'Submit your placement details for coordinator review.',
            icon: Icons.business_center_outlined,
            color: AppColors.warning,
            actionLabel: 'Submit',
            onActionPressed: () => context.go(AppRoutes.internship),
          );
        }
        return StudentDashboardSummaryCard(
          title: 'Current Internship',
          value: internship.status.label,
          description: '${internship.companyName} • ${internship.state}',
          icon: Icons.business_center_outlined,
          color: _statusColor(internship.status),
          actionLabel: 'View',
          onActionPressed: () => context.go(AppRoutes.internship),
        );
      },
    );
  }

  Color _statusColor(InternshipStatus status) {
    return switch (status) {
      InternshipStatus.pendingReview => AppColors.warning,
      InternshipStatus.approved ||
      InternshipStatus.assigned ||
      InternshipStatus.active ||
      InternshipStatus.completed => AppColors.success,
      InternshipStatus.rejected => AppColors.error,
      InternshipStatus.draft ||
      InternshipStatus.archived => AppColors.secondary,
    };
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${user.firstName}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${user.department}${user.matricNumber == null ? '' : ' • ${user.matricNumber}'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
