import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../providers/lecturer_attendance_provider.dart';

/// Lecturer screen showing recent attendance across assigned students.
class LecturerAttendanceScreen extends ConsumerWidget {
  /// Creates the lecturer attendance screen.
  const LecturerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceValue = ref.watch(lecturerAttendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: attendanceValue.when(
        loading: () => const AppLoading(message: 'Loading attendance...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load attendance. Please try again.',
          onRetry: () => ref.invalidate(lecturerAttendanceProvider),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const AppEmptyState(
              title: 'No Attendance Yet',
              message:
                  'Once your assigned students start checking in, records will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(lecturerAttendanceProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _AttendanceRecordCard(record: records[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});

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
                child: Text(record.studentName, style: textTheme.titleMedium),
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
            '${record.companyName} • ${_formatDate(record.date)}',
            style: textTheme.bodySmall,
          ),
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
