import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/location_notice.dart';
import '../controllers/attendance_state.dart';
import '../widgets/attendance_location_chip.dart';
import '../providers/attendance_providers.dart';
import '../widgets/attendance_calendar.dart';

/// Student attendance: check in and out for today, and the month's record
/// as a stamp calendar.
class StudentAttendanceScreen extends ConsumerWidget {
  /// Creates the student attendance screen.
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipValue = ref.watch(internshipControllerProvider);
    final attendanceValue = ref.watch(attendanceControllerProvider);

    ref.listen(attendanceControllerProvider, (previous, next) {
      final state = next.value;
      final message = state?.errorMessage ?? state?.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return internshipValue.when(
      loading: () => const AppLoading(layout: AppLoadingLayout.dashboard),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Your placement couldn’t be loaded. Check your connection '
            'and try again.',
        onRetry: () =>
            ref.read(internshipControllerProvider.notifier).refresh(),
      ),
      data: (internshipState) {
        final internship = internshipState.currentInternship;
        if (internship?.status == InternshipStatus.completed) {
          return const AppEmptyState(
            icon: Icons.verified_outlined,
            tone: AppTone.success,
            title: 'Internship completed',
            message:
                'Attendance is closed now that your internship is over. Your '
                'records are kept.',
          );
        }
        if (internship == null ||
            internship.status != InternshipStatus.active) {
          return const AppEmptyState(
            icon: Icons.event_available_outlined,
            tone: AppTone.sky,
            title: 'Attendance opens when your internship starts',
            message:
                'Once your coordinator starts your internship, you’ll check in '
                'and out here each working day.',
          );
        }

        return attendanceValue.when(
          loading: () => const AppLoading(layout: AppLoadingLayout.dashboard),
          error: (error, stackTrace) => AppErrorState(
            message:
                'Your attendance couldn’t be loaded. Check your '
                'connection and try again.',
            onRetry: () =>
                ref.read(attendanceControllerProvider.notifier).refresh(),
          ),
          data: (state) =>
              _AttendanceBody(state: state, internship: internship),
        );
      },
    );
  }
}

class _AttendanceBody extends ConsumerWidget {
  const _AttendanceBody({required this.state, required this.internship});

  final AttendanceState state;
  final InternshipModel internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = state.history.take(8).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(attendanceControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ResponsiveColumns(
            primary: [
              FadeSlideIn(child: _TodayCard(state: state)),
              FadeSlideIn(
                index: 1,
                child: SectionCard(
                  title: 'Recent days',
                  child: recent.isEmpty
                      ? const AppEmptyState(
                          compact: true,
                          icon: Icons.history_rounded,
                          tone: AppTone.sky,
                          title: 'No days yet',
                          message: 'Each day you check in is listed here.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < recent.length; i++) ...[
                              if (i > 0) const Divider(),
                              _DayRow(record: recent[i]),
                            ],
                          ],
                        ),
                ),
              ),
            ],
            secondary: [
              FadeSlideIn(
                index: 2,
                child: AppCard(
                  child: AttendanceCalendar(
                    records: state.history,
                    since: internship.activatedAt ?? internship.startDate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Today's check-in, as the thing the page is really for.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final today = state.today;
    final controller = ref.read(attendanceControllerProvider.notifier);

    final (headline, detail) = today == null
        ? ('You haven’t checked in yet', 'Check in when you arrive at work.')
        : today.checkOutTime == null
        ? (
            'Checked in at ${Formatters.time(today.checkInTime)}',
            'Check out before you leave for the day.',
          )
        : (
            'Done for today',
            'You were in from ${Formatters.time(today.checkInTime)} to '
                '${Formatters.time(today.checkOutTime!)}.',
          );

    return AppCard(
      color: AppColors.sky,
      borderColor: AppColors.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.day(Formatters.todayUtc()).toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.inkDeep.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            headline,
            style: textTheme.headlineSmall?.copyWith(color: AppColors.inkDeep),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.inkDeep.withValues(alpha: 0.75),
            ),
          ),
          // Shown to the student too, not just the lecturer: they should
          // know what was recorded about them and have the chance to fix a
          // phone setting rather than be quietly flagged.
          if (today != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AttendanceLocationChip(record: today),
            ),
          ],
          // A check-in held back because the phone's location couldn't be
          // read. Says what is wrong and offers the way out, rather than
          // saving an unconfirmed record without a word.
          if (today == null && state.locationNotice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _LocationNotice(reason: state.locationNotice!),
          ],
          if (today == null || today.checkOutTime == null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: today == null
                  ? (state.locationNotice == null ? 'Check in' : 'Try again')
                  : 'Check out',
              icon: today == null ? Icons.login_rounded : Icons.logout_rounded,
              isLoading: state.isProcessing,
              onPressed: today == null
                  ? controller.checkIn
                  : controller.checkOut,
            ),
          ],
          // Never a dead end: the student can always go ahead. It is their
          // attendance, and a phone's GPS is not always fixable on the spot.
          if (today == null && state.locationNotice != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Check in without confirming',
              variant: AppButtonVariant.text,
              onPressed: state.isProcessing
                  ? null
                  : () => controller.checkIn(withoutLocation: true),
            ),
          ],
        ],
      ),
    );
  }
}

/// Explains why a location reading is missing, and offers the one setting
/// that would fix it.
class _LocationNotice extends ConsumerWidget {
  const _LocationNotice({required this.reason});

  final LocationUnavailable reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = LocationNotice.of(reason);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTone.warning.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                Text(
                  notice.message,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                if (notice.actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: notice.actionLabel!,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openSettings(ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(WidgetRef ref) async {
    final location = ref.read(locationServiceProvider);
    switch (LocationNotice.of(reason).action) {
      case LocationNoticeAction.openLocationSettings:
        await location.openLocationSettings();
      case LocationNoticeAction.openAppSettings:
        await location.openAppSettings();
      case LocationNoticeAction.none:
        break;
    }
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.record});

  final AttendanceModel record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = switch (record.status) {
      AttendanceStatus.completed => ('Present', AppTone.sky),
      AttendanceStatus.checkedIn => ('Checked in', AppTone.ink),
      AttendanceStatus.missed => ('Missed', AppTone.error),
      AttendanceStatus.incomplete => ('No check-out', AppTone.warning),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.day(record.date), style: textTheme.titleSmall),
                Text(
                  record.checkOutTime == null
                      ? 'In ${Formatters.time(record.checkInTime)}'
                      : '${Formatters.time(record.checkInTime)} – '
                            '${Formatters.time(record.checkOutTime!)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppStatusChip(label: label, tone: tone),
        ],
      ),
    );
  }
}
