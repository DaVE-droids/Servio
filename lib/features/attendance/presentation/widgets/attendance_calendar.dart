import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/attendance_model.dart';

/// A month of attendance as a stamp card: every day the student checked in
/// and out is stamped sky blue, a day checked into but never out is amber,
/// and a past working day with no record is greyed out.
///
/// Used by the student's own attendance page and by lecturers and
/// coordinators looking at a student, so all three read attendance the
/// same way.
class AttendanceCalendar extends StatefulWidget {
  /// Creates an attendance calendar.
  const AttendanceCalendar({required this.records, this.since, super.key});

  /// Attendance records, in any order.
  final List<AttendanceModel> records;

  /// First day that counts (the internship's start). Working days before it
  /// are never shown as missed.
  final DateTime? since;

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

enum _DayKind { present, incomplete, noRecord, upcoming, weekend, outside }

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _month = _monthOf(Formatters.todayUtc());

  static DateTime _monthOf(DateTime day) => DateTime.utc(day.year, day.month);

  static String _key(DateTime day) {
    final d = day.toUtc();
    return '${d.year}-${d.month}-${d.day}';
  }

  Map<String, AttendanceModel> get _byDay => {
    for (final record in widget.records) _key(record.date): record,
  };

  DateTime get _firstMonth {
    final candidates = [
      if (widget.since != null) widget.since!.toUtc(),
      for (final record in widget.records) record.date.toUtc(),
    ];
    if (candidates.isEmpty) {
      return _monthOf(Formatters.todayUtc());
    }
    candidates.sort();
    return _monthOf(candidates.first);
  }

  _DayKind _kindOf(DateTime day, Map<String, AttendanceModel> byDay) {
    final today = Formatters.todayUtc();
    final record = byDay[_key(day)];
    if (record != null) {
      return record.checkOutTime != null
          ? _DayKind.present
          : day == today
          ? _DayKind.present
          : _DayKind.incomplete;
    }
    if (day.weekday >= DateTime.saturday) {
      return _DayKind.weekend;
    }
    if (!day.isBefore(today)) {
      return _DayKind.upcoming;
    }
    final since = widget.since;
    if (since != null &&
        day.isBefore(DateTime.utc(since.year, since.month, since.day))) {
      return _DayKind.outside;
    }
    return _DayKind.noRecord;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final byDay = _byDay;
    final today = Formatters.todayUtc();
    final canGoBack = _month.isAfter(_firstMonth);
    final canGoForward = _month.isBefore(_monthOf(today));

    // Monday-first grid: working days read left to right, weekend last.
    final first = _month;
    final leading = first.weekday - 1;
    final daysInMonth = DateTime.utc(first.year, first.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime.utc(first.year, first.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final counts = <_DayKind, int>{};
    for (final day in cells.whereType<DateTime>()) {
      final kind = _kindOf(day, byDay);
      counts[kind] = (counts[kind] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                Formatters.monthYear(_month),
                style: textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: canGoBack
                  ? () => setState(
                      () =>
                          _month = DateTime.utc(_month.year, _month.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: canGoForward
                  ? () => setState(
                      () =>
                          _month = DateTime.utc(_month.year, _month.month + 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(child: Text(label, style: textTheme.labelMedium)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _DayCell(
                        day: cells[row * 7 + col],
                        kind: cells[row * 7 + col] == null
                            ? null
                            : _kindOf(cells[row * 7 + col]!, byDay),
                        isToday: cells[row * 7 + col] == today,
                        record: cells[row * 7 + col] == null
                            ? null
                            : byDay[_key(cells[row * 7 + col]!)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Tally(
              label: 'Present',
              value: counts[_DayKind.present] ?? 0,
              fill: AppColors.sky,
            ),
            const SizedBox(width: AppSpacing.xs),
            _Tally(
              label: 'No check-out',
              value: counts[_DayKind.incomplete] ?? 0,
              fill: AppColors.warningSoft,
            ),
            const SizedBox(width: AppSpacing.xs),
            _Tally(
              label: 'No record',
              value: counts[_DayKind.noRecord] ?? 0,
              fill: AppColors.mist,
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.kind,
    required this.isToday,
    required this.record,
  });

  final DateTime? day;
  final _DayKind? kind;
  final bool isToday;
  final AttendanceModel? record;

  @override
  Widget build(BuildContext context) {
    if (day == null || kind == null) {
      return const AspectRatio(aspectRatio: 1.15, child: SizedBox());
    }
    final (fill, text) = switch (kind!) {
      _DayKind.present => (AppColors.sky, AppColors.inkDeep),
      _DayKind.incomplete => (AppColors.warningSoft, AppColors.warning),
      _DayKind.noRecord => (AppColors.mist, AppColors.textTertiary),
      _DayKind.upcoming => (Colors.transparent, AppColors.textPrimary),
      _DayKind.weekend => (Colors.transparent, AppColors.textTertiary),
      _DayKind.outside => (Colors.transparent, AppColors.textTertiary),
    };

    final description = switch (kind!) {
      _DayKind.present =>
        record?.checkOutTime == null
            ? 'Checked in at ${Formatters.time(record!.checkInTime)}'
            : 'Present, ${Formatters.time(record!.checkInTime)} to '
                  '${Formatters.time(record!.checkOutTime!)}',
      _DayKind.incomplete =>
        'Checked in at ${Formatters.time(record!.checkInTime)}, no check-out',
      _DayKind.noRecord => 'No attendance recorded',
      _ => null,
    };

    final cell = AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: isToday && kind == _DayKind.upcoming ? AppColors.ink : fill,
          borderRadius: BorderRadius.circular(AppRadii.control - 2),
          border: isToday && kind != _DayKind.upcoming
              ? Border.all(color: AppColors.ink, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day!.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: kind == _DayKind.present || isToday
                ? FontWeight.w700
                : FontWeight.w500,
            fontFeatures: AppTypography.tabular,
            color: isToday && kind == _DayKind.upcoming ? Colors.white : text,
          ),
        ),
      ),
    );

    final label =
        '${Formatters.day(day!)}${description == null ? '' : '. $description'}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: description == null
          ? cell
          : Tooltip(message: description, child: cell),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value, required this.fill});

  final String label;
  final int value;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.inkDeep.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '$value',
              style: textTheme.titleLarge?.copyWith(
                fontFeatures: AppTypography.tabular,
                color: AppColors.inkDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
