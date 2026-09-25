import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/enums/logbook_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../attendance/presentation/controllers/attendance_state.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../../internship/presentation/widgets/placement_journey_card.dart';
import '../../../logbook/presentation/controllers/logbook_state.dart';
import '../../../logbook/presentation/providers/logbook_providers.dart';
import '../../../notifications/data/models/notification_model.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

/// The student's home: where their placement is on its journey, today's
/// attendance and logbook (with the actions right there), and progress
/// once the internship is running.
class StudentDashboardScreen extends ConsumerWidget {
  /// Creates the student dashboard screen.
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(profileControllerProvider);
    final internshipValue = ref.watch(internshipControllerProvider);

    if ((profileValue.isLoading && !profileValue.hasValue) ||
        (internshipValue.isLoading && !internshipValue.hasValue)) {
      return const AppLoading(layout: AppLoadingLayout.dashboard);
    }
    if (internshipValue.hasError && !internshipValue.hasValue) {
      return AppErrorState(
        message:
            'Your dashboard couldn’t be loaded. Check your connection '
            'and try again.',
        onRetry: () =>
            ref.read(internshipControllerProvider.notifier).refresh(),
      );
    }

    final user = profileValue.value?.user;
    final internship = internshipValue.value?.currentInternship;
    final isActive = internship?.status == InternshipStatus.active;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(internshipControllerProvider.notifier).refresh();
        ref
          ..invalidate(notificationsControllerProvider)
          ..invalidate(internshipProgressProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.day(Formatters.todayUtc()).toUpperCase(),
                  style: textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  user == null
                      ? Formatters.greeting()
                      : '${Formatters.greeting()}, ${user.firstName}',
                  style: textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 1,
            child: PlacementJourneyCard(
              internship: internship,
              action: internship == null
                  ? AppButton(
                      label: 'Submit my placement',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go(AppRoutes.internship),
                    )
                  : null,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: AppSpacing.md),
            const FadeSlideIn(index: 2, child: _TodayRow()),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 3,
              child: _ProgressTiles(internship: internship!),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const FadeSlideIn(index: 4, child: _RecentNotifications()),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Today's two jobs, side by side on wide screens: attendance and the
/// logbook entry. Check-in and check-out happen right here.
class _TodayRow extends ConsumerWidget {
  const _TodayRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceControllerProvider);
    final logbook = ref.watch(logbookControllerProvider);

    final cards = [
      _AttendanceTodayCard(value: attendance),
      _LogbookTodayCard(value: logbook),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: AppSpacing.md),
              cards[1],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[1]),
            ],
          ),
        );
      },
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.tone,
    required this.icon,
    required this.label,
    required this.headline,
    required this.detail,
    this.action,
  });

  final AppTone tone;
  final IconData icon;
  final String label;
  final String headline;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.fill,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Icon(icon, size: 19, color: AppColors.inkDeep),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label.toUpperCase(), style: textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(headline, style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(detail, style: textTheme.bodySmall),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class _AttendanceTodayCard extends ConsumerWidget {
  const _AttendanceTodayCard({required this.value});

  final AsyncValue<AttendanceState> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const label = 'Attendance today';
    final state = value.value;
    if (state == null) {
      return _TodayCard(
        tone: AppTone.sky,
        icon: Icons.event_available_outlined,
        label: label,
        headline: value.hasError ? 'Unavailable' : 'Checking…',
        detail: value.hasError
            ? 'Pull down to try again.'
            : 'Looking up today’s record.',
      );
    }
    final today = state.today;
    final controller = ref.read(attendanceControllerProvider.notifier);

    if (today == null) {
      return _TodayCard(
        tone: AppTone.sky,
        icon: Icons.event_available_outlined,
        label: label,
        headline: 'Not checked in',
        detail: 'Check in when you arrive at work.',
        action: AppButton(
          label: 'Check in',
          icon: Icons.login_rounded,
          isLoading: state.isProcessing,
          onPressed: controller.checkIn,
        ),
      );
    }
    if (today.checkOutTime == null) {
      return _TodayCard(
        tone: AppTone.sky,
        icon: Icons.event_available_outlined,
        label: label,
        headline: 'Checked in at ${Formatters.time(today.checkInTime)}',
        detail: 'Remember to check out before you leave.',
        action: AppButton(
          label: 'Check out',
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.secondary,
          isLoading: state.isProcessing,
          onPressed: controller.checkOut,
        ),
      );
    }
    return _TodayCard(
      tone: AppTone.sky,
      icon: Icons.event_available_outlined,
      label: label,
      headline: 'Done for today',
      detail:
          '${Formatters.time(today.checkInTime)} – '
          '${Formatters.time(today.checkOutTime!)}',
    );
  }
}

class _LogbookTodayCard extends StatelessWidget {
  const _LogbookTodayCard({required this.value});

  final AsyncValue<LogbookState> value;

  @override
  Widget build(BuildContext context) {
    const label = 'Logbook today';
    final state = value.value;
    if (state == null) {
      return _TodayCard(
        tone: AppTone.blush,
        icon: Icons.menu_book_outlined,
        label: label,
        headline: value.hasError ? 'Unavailable' : 'Checking…',
        detail: value.hasError
            ? 'Pull down to try again.'
            : 'Looking up today’s entry.',
      );
    }
    final entry = state.today;
    final (headline, detail, actionLabel, primary) = switch (entry?.status) {
      null => (
        'Not written yet',
        'Record what you worked on before you finish.',
        'Write today’s entry',
        true,
      ),
      LogbookStatus.pending => (
        'Waiting for review',
        'You can still edit it until your lecturer reviews it.',
        'Open entry',
        false,
      ),
      LogbookStatus.changesRequested => (
        'Changes requested',
        'Your lecturer left a note on this entry.',
        'Update entry',
        true,
      ),
      LogbookStatus.approved => (
        'Approved',
        'Your lecturer approved today’s entry.',
        'Open logbook',
        false,
      ),
    };
    return _TodayCard(
      tone: AppTone.blush,
      icon: Icons.menu_book_outlined,
      label: label,
      headline: headline,
      detail: detail,
      action: AppButton(
        label: actionLabel,
        variant: primary
            ? AppButtonVariant.primary
            : AppButtonVariant.secondary,
        onPressed: () => context.go(AppRoutes.logbook),
      ),
    );
  }
}

class _ProgressTiles extends ConsumerWidget {
  const _ProgressTiles({required this.internship});

  final InternshipModel internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref
        .watch(internshipProgressProvider(internship.internshipId))
        .value;
    final today = Formatters.todayUtc();
    final end = internship.endDate.toUtc();
    final daysLeft = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(today).inDays;

    return StatGrid(
      maxColumns: 3,
      children: [
        StatTile(
          value: progress == null ? '–' : '${progress.attendanceDays}',
          label: 'Days attended',
          icon: Icons.event_available_outlined,
          tone: AppTone.sky,
          onTap: () => context.go(AppRoutes.attendance),
        ),
        StatTile(
          value: progress == null ? '–' : '${progress.logbookApproved}',
          label: 'Entries approved',
          icon: Icons.menu_book_outlined,
          tone: AppTone.blush,
          onTap: () => context.go(AppRoutes.logbook),
        ),
        StatTile(
          value: daysLeft < 0 ? '0' : '$daysLeft',
          label: daysLeft == 1 ? 'Day to go' : 'Days to go',
          icon: Icons.flag_outlined,
          caption: 'Ends ${Formatters.date(internship.endDate)}',
        ),
      ],
    );
  }
}

class _RecentNotifications extends ConsumerWidget {
  const _RecentNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsControllerProvider);
    final notifications = value.value?.notifications;
    final recent =
        notifications?.take(3).toList() ?? const <NotificationModel>[];
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      title: 'Latest updates',
      trailing: recent.isEmpty
          ? null
          : TextButton(
              onPressed: () => context.push(AppRoutes.notifications),
              child: const Text('View all'),
            ),
      child: notifications == null
          ? const SizedBox(height: 48)
          : recent.isEmpty
          ? Text(
              'Nothing yet. Decisions about your placement, logbook reviews, '
              'and visit reports will show up here.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: [
                for (final notification in recent)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
                                  ? AppColors.line
                                  : AppColors.blushStrong,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              Text(
                                notification.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          Formatters.relative(notification.createdAt),
                          style: textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
