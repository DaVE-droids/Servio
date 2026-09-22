import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/enums/logbook_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/dashboard_summary_card.dart';
import '../../../attendance/presentation/controllers/attendance_state.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../internship/presentation/controllers/internship_state.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../logbook/presentation/controllers/logbook_state.dart';
import '../../../logbook/presentation/providers/logbook_providers.dart';
import '../../../notifications/presentation/controllers/notifications_state.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Student dashboard showing the current user's placement overview.
class StudentDashboardScreen extends ConsumerWidget {
  /// Creates the student dashboard screen.
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(profileControllerProvider);
    final internshipValue = ref.watch(internshipControllerProvider);
    final attendanceValue = ref.watch(attendanceControllerProvider);
    final logbookValue = ref.watch(logbookControllerProvider);
    final notificationsValue = ref.watch(notificationsControllerProvider);

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
              _DashboardGrid(
                internshipValue: internshipValue,
                attendanceValue: attendanceValue,
                logbookValue: logbookValue,
              ),
              const SizedBox(height: AppSpacing.md),
              _RecentNotificationsCard(value: notificationsValue),
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
  const _DashboardGrid({
    required this.internshipValue,
    required this.attendanceValue,
    required this.logbookValue,
  });

  final AsyncValue<InternshipState> internshipValue;
  final AsyncValue<AttendanceState> attendanceValue;
  final AsyncValue<LogbookState> logbookValue;

  /// Fixed card height. Chosen to comfortably fit an icon/title row, a
  /// value line, a two-line description, and an optional action button —
  /// a childAspectRatio-based height previously overflowed on narrow
  /// screens once a card's button was showing.
  static const _cardHeight = 210.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final cards = [
          _internshipCard(context),
          _attendanceCard(context),
          _logbookCard(context),
        ];
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: _cardHeight,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _attendanceCard(BuildContext context) {
    return attendanceValue.when(
      loading: () => const DashboardSummaryCard(
        title: "Today's Attendance",
        value: 'Loading...',
        description: 'Checking your attendance status.',
        icon: Icons.fact_check_outlined,
        color: AppColors.information,
      ),
      error: (error, stackTrace) => const DashboardSummaryCard(
        title: "Today's Attendance",
        value: 'Unavailable',
        description: 'Unable to load your attendance status right now.',
        icon: Icons.fact_check_outlined,
        color: AppColors.error,
      ),
      data: (state) {
        final today = state.today;
        if (today == null) {
          final isActive = switch (internshipValue) {
            AsyncData(:final value) =>
              value.currentInternship?.status == InternshipStatus.active,
            _ => false,
          };
          return DashboardSummaryCard(
            title: "Today's Attendance",
            value: 'Not checked in',
            description: isActive
                ? "You haven't checked in today."
                : 'Check in once your internship is active.',
            icon: Icons.fact_check_outlined,
            color: AppColors.warning,
            actionLabel: 'View',
            onActionPressed: () => context.go(AppRoutes.attendance),
          );
        }
        final checkedOut = today.checkOutTime != null;
        return DashboardSummaryCard(
          title: "Today's Attendance",
          value: checkedOut ? 'Completed' : 'Checked in',
          description: checkedOut
              ? 'Checked in and out for today.'
              : "Checked in — don't forget to check out.",
          icon: Icons.fact_check_outlined,
          color: checkedOut ? AppColors.success : AppColors.information,
          actionLabel: 'View',
          onActionPressed: () => context.go(AppRoutes.attendance),
        );
      },
    );
  }

  /// Today's logbook entry at a glance, so a student sees what's still
  /// outstanding without opening the logbook tab.
  Widget _logbookCard(BuildContext context) {
    const title = "Today's Logbook";
    const icon = Icons.menu_book_outlined;
    final isActive = switch (internshipValue) {
      AsyncData(:final value) =>
        value.currentInternship?.status == InternshipStatus.active,
      _ => false,
    };
    if (!isActive) {
      return const DashboardSummaryCard(
        title: title,
        value: 'Not open yet',
        description: 'Your logbook opens once your internship is active.',
        icon: icon,
        color: AppColors.secondary,
      );
    }

    return logbookValue.when(
      loading: () => const DashboardSummaryCard(
        title: title,
        value: 'Loading...',
        description: "Checking today's entry.",
        icon: icon,
        color: AppColors.information,
      ),
      error: (error, stackTrace) => const DashboardSummaryCard(
        title: title,
        value: 'Unavailable',
        description: 'Unable to load your logbook right now.',
        icon: icon,
        color: AppColors.error,
      ),
      data: (state) {
        final (value, description, color, action) = switch (state.today?.status) {
          null => (
            'Not written yet',
            "Record what you did today before you finish.",
            AppColors.warning,
            'Write Entry',
          ),
          LogbookStatus.pending => (
            'Awaiting review',
            'Your lecturer has not reviewed today\'s entry yet.',
            AppColors.information,
            'View',
          ),
          LogbookStatus.changesRequested => (
            'Changes requested',
            'Your lecturer asked you to update this entry.',
            AppColors.warning,
            'Edit Entry',
          ),
          LogbookStatus.approved => (
            'Approved',
            "Today's entry has been approved.",
            AppColors.success,
            'View',
          ),
        };
        return DashboardSummaryCard(
          title: title,
          value: value,
          description: description,
          icon: icon,
          color: color,
          actionLabel: action,
          onActionPressed: () => context.go(AppRoutes.logbook),
        );
      },
    );
  }

  Widget _internshipCard(BuildContext context) {
    return internshipValue.when(
      loading: () => const DashboardSummaryCard(
        title: 'Current Internship',
        value: 'Loading...',
        description: 'Checking your submitted placement status.',
        icon: Icons.business_center_outlined,
        color: AppColors.information,
      ),
      error: (error, stackTrace) => const DashboardSummaryCard(
        title: 'Current Internship',
        value: 'Unavailable',
        description: 'Unable to load your placement status right now.',
        icon: Icons.business_center_outlined,
        color: AppColors.error,
      ),
      data: (state) {
        final internship = state.currentInternship;
        if (internship == null) {
          return DashboardSummaryCard(
            title: 'Current Internship',
            value: 'Not submitted yet',
            description:
                'Submit your placement details for coordinator review.',
            icon: Icons.business_center_outlined,
            color: AppColors.warning,
            actionLabel: 'Submit',
            onActionPressed: () => context.push(AppRoutes.internship),
          );
        }
        return DashboardSummaryCard(
          title: 'Current Internship',
          value: internship.status.label,
          description: '${internship.companyName} • ${internship.state}',
          icon: Icons.business_center_outlined,
          color: _statusColor(internship.status),
          actionLabel: 'View',
          onActionPressed: () => context.push(AppRoutes.internship),
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

/// The student's three most recent notifications, with a way to see the
/// rest. Unread ones are shown in bold with a dot.
class _RecentNotificationsCard extends StatelessWidget {
  const _RecentNotificationsCard({required this.value});

  final AsyncValue<NotificationsState> value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notifications = switch (value) {
      AsyncData(:final value) => value.notifications,
      _ => null,
    };
    final recent = notifications?.take(3).toList() ?? const [];

    return AppCard(
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
              Expanded(
                child: Text('Recent Notifications', style: textTheme.titleMedium),
              ),
              if (recent.isNotEmpty)
                TextButton(
                  onPressed: () => context.go(AppRoutes.notifications),
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (notifications == null)
            Text('Loading notifications...', style: textTheme.bodyMedium)
          else if (recent.isEmpty)
            Text(
              'No notifications yet. Updates about your placement, logbook, '
              'and supervision visits will appear here.',
              style: textTheme.bodyMedium,
            )
          else
            for (final notification in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Colors.transparent
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                            ),
                          ),
                          Text(
                            notification.message,
                            style: textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
