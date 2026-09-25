import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../providers/lecturer_attendance_provider.dart';

/// Recent attendance across the lecturer's students, grouped by day.
class LecturerAttendanceScreen extends ConsumerWidget {
  /// Creates the lecturer attendance screen.
  const LecturerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceValue = ref.watch(lecturerAttendanceProvider);

    return attendanceValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Attendance couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.invalidate(lecturerAttendanceProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AppEmptyState(
            icon: Icons.event_available_outlined,
            tone: AppTone.sky,
            title: 'No attendance yet',
            message:
                'Once your students start checking in, their days appear '
                'here.',
          );
        }

        final byDay = <DateTime, List<AttendanceModel>>{};
        for (final record in records) {
          final day = record.date.toUtc();
          byDay
              .putIfAbsent(DateTime.utc(day.year, day.month, day.day), () => [])
              .add(record);
        }
        final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
        final today = Formatters.todayUtc();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(lecturerAttendanceProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final day in days) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    4,
                    AppSpacing.sm,
                    4,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    (day == today
                            ? 'Today'
                            : day == today.subtract(const Duration(days: 1))
                            ? 'Yesterday'
                            : Formatters.day(day))
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Column(
                    children: [
                      for (var i = 0; i < byDay[day]!.length; i++) ...[
                        if (i > 0) const Divider(indent: 68),
                        _AttendanceRow(record: byDay[day]![i]),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final AttendanceModel record;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (record.status) {
      AttendanceStatus.completed => ('Present', AppTone.sky),
      AttendanceStatus.checkedIn => ('Checked in', AppTone.ink),
      AttendanceStatus.missed => ('Missed', AppTone.error),
      AttendanceStatus.incomplete => ('No check-out', AppTone.warning),
    };
    return ListTile(
      leading: AppAvatar(name: record.studentName, size: 40),
      title: Text(record.studentName),
      subtitle: Text(
        '${record.companyName} · ${Formatters.time(record.checkInTime)}'
        '${record.checkOutTime == null ? '' : '–${Formatters.time(record.checkOutTime!)}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AppStatusChip(label: label, tone: tone),
    );
  }
}
