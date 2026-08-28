import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../data/models/attendance_model.dart';
import '../controllers/attendance_state.dart';
import '../providers/attendance_providers.dart';

/// Student screen for daily check-in/check-out and attendance history.
class StudentAttendanceScreen extends ConsumerWidget {
  /// Creates the student attendance screen.
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipValue = ref.watch(internshipControllerProvider);
    final attendanceValue = ref.watch(attendanceControllerProvider);

    ref.listen(attendanceControllerProvider, (previous, next) {
      final state = switch (next) {
        AsyncData(:final value) => value,
        _ => null,
      };
      final message = state?.errorMessage ?? state?.successMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return internshipValue.when(
      loading: () => const AppLoading(message: 'Loading attendance...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your internship. Please try again.',
        onRetry: () => ref.read(internshipControllerProvider.notifier).refresh(),
      ),
      data: (internshipState) {
        final internship = internshipState.currentInternship;
        if (internship == null || internship.status != InternshipStatus.active) {
          return const AppEmptyState(
            title: 'Attendance Unavailable',
            message:
                'Attendance will be available once your internship is active.',
          );
        }

        return attendanceValue.when(
          loading: () => const AppLoading(message: 'Loading attendance...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Unable to load your attendance. Please try again.',
            onRetry: () =>
                ref.read(attendanceControllerProvider.notifier).refresh(),
          ),
          data: (state) => _AttendanceBody(state: state),
        );
      },
    );
  }
}

class _AttendanceBody extends ConsumerWidget {
  const _AttendanceBody({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = state.today;

    return RefreshIndicator(
      onRefresh: () => ref.read(attendanceControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            "Today's Attendance",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (today == null) ...[
                  Text(
                    'Not checked in yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Check In',
                    isLoading: state.isProcessing,
                    onPressed: state.isProcessing
                        ? null
                        : () =>
                              ref.read(attendanceControllerProvider.notifier).checkIn(),
                  ),
                ] else if (today.checkOutTime == null) ...[
                  Text(
                    'Checked in at ${_formatTime(today.checkInTime)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Check Out',
                    isLoading: state.isProcessing,
                    onPressed: state.isProcessing
                        ? null
                        : () => ref
                              .read(attendanceControllerProvider.notifier)
                              .checkOut(),
                  ),
                ] else ...[
                  Text(
                    'Checked in at ${_formatTime(today.checkInTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Checked out at ${_formatTime(today.checkOutTime!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AppStatusChip(
                    label: 'Completed',
                    type: AppStatusChipType.success,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Attendance History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            const AppEmptyState(
              title: 'No Attendance Yet',
              message: 'Your check-in history will appear here.',
            )
          else
            for (final record in state.history) ...[
              _HistoryCard(record: record),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final AttendanceModel record;

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
                child: Text(_formatDate(record.date), style: textTheme.titleMedium),
              ),
              AppStatusChip(
                label: record.status.label,
                type: switch (record.status) {
                  AttendanceStatus.completed => AppStatusChipType.success,
                  AttendanceStatus.checkedIn => AppStatusChipType.info,
                  AttendanceStatus.missed => AppStatusChipType.error,
                  AttendanceStatus.incomplete => AppStatusChipType.warning,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'In: ${_formatTime(record.checkInTime)}'
            '${record.checkOutTime == null ? '' : ' • Out: ${_formatTime(record.checkOutTime!)}'}',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

String _formatTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
