import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../supervision/presentation/providers/supervision_providers.dart';
import '../providers/assigned_students_provider.dart';
import '../providers/lecturer_attendance_provider.dart';
import '../providers/pending_logbook_reviews_provider.dart';

/// The lecturer's home: how many students they supervise, and what's
/// waiting on them — logbook entries to review and students not yet
/// visited.
class LecturerDashboardScreen extends ConsumerWidget {
  /// Creates the lecturer dashboard screen.
  const LecturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileControllerProvider).value?.user;
    final studentsValue = ref.watch(assignedStudentsProvider);
    final reviews = ref.watch(pendingLogbookReviewsProvider).value;
    final lastVisits = ref.watch(lastVisitByInternshipProvider).value;
    final attendance = ref.watch(lecturerAttendanceProvider).value;
    final textTheme = Theme.of(context).textTheme;

    if (studentsValue.isLoading && !studentsValue.hasValue) {
      return const AppLoading(layout: AppLoadingLayout.dashboard);
    }
    final students = studentsValue.value ?? const [];
    final today = Formatters.todayUtc();
    final checkedInToday = attendance
        ?.where((record) => record.date.toUtc() == today)
        .toList();
    final notVisited = lastVisits == null
        ? null
        : students
              .where(
                (internship) =>
                    internship.status == InternshipStatus.active &&
                    !lastVisits.containsKey(internship.internshipId),
              )
              .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(assignedStudentsProvider)
          ..invalidate(pendingLogbookReviewsProvider)
          ..invalidate(lecturerReportsProvider)
          ..invalidate(lecturerAttendanceProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.day(today).toUpperCase(),
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
            child: StatGrid(
              children: [
                StatTile(
                  value: '${students.length}',
                  label: 'My students',
                  icon: Icons.groups_outlined,
                  tone: AppTone.sky,
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.assignedStudents),
                ),
                StatTile(
                  value: reviews == null ? '–' : '${reviews.length}',
                  label: 'Entries to review',
                  icon: Icons.rate_review_outlined,
                  tone: AppTone.blush,
                  onTap: () => context.go(AppRoutes.logbook),
                ),
                StatTile(
                  value: notVisited == null ? '–' : '${notVisited.length}',
                  label: 'Not visited yet',
                  icon: Icons.person_pin_circle_outlined,
                  tone: (notVisited?.isNotEmpty ?? false)
                      ? AppTone.warning
                      : AppTone.ink,
                ),
                StatTile(
                  value: checkedInToday == null
                      ? '–'
                      : '${checkedInToday.length}',
                  label: 'Checked in today',
                  icon: Icons.event_available_outlined,
                  tone: AppTone.sky,
                  onTap: () => context.go(AppRoutes.attendance),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 2,
            child: SectionCard(
              title: 'Needs your attention',
              child: _AttentionList(
                reviewCount: reviews?.length ?? 0,
                oldestReview: reviews == null || reviews.isEmpty
                    ? null
                    : (reviews.map((entry) => entry.date).toList()..sort())
                          .first,
                notVisited: notVisited ?? const [],
                hasStudents: students.isNotEmpty,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 3,
            child: SectionCard(
              title: 'Today’s check-ins',
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.attendance),
                child: const Text('All attendance'),
              ),
              child: checkedInToday == null
                  ? const SizedBox(height: 48)
                  : checkedInToday.isEmpty
                  ? const AppEmptyState(
                      compact: true,
                      icon: Icons.event_busy_outlined,
                      tone: AppTone.sky,
                      title: 'No check-ins yet today',
                      message: 'Students appear here as they check in.',
                    )
                  : Column(
                      children: [
                        for (final record in checkedInToday)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: AppAvatar(
                              name: record.studentName,
                              size: 38,
                            ),
                            title: Text(record.studentName),
                            subtitle: Text(record.companyName),
                            trailing: Text(
                              record.checkOutTime == null
                                  ? 'In ${Formatters.time(record.checkInTime)}'
                                  : '${Formatters.time(record.checkInTime)}–'
                                        '${Formatters.time(record.checkOutTime!)}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({
    required this.reviewCount,
    required this.oldestReview,
    required this.notVisited,
    required this.hasStudents,
  });

  final int reviewCount;
  final DateTime? oldestReview;
  final List<InternshipModel> notVisited;
  final bool hasStudents;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (reviewCount > 0)
        _AttentionItem(
          icon: Icons.rate_review_outlined,
          tone: AppTone.blush,
          title:
              '${Formatters.count(reviewCount, 'logbook entry', 'logbook entries')} to review',
          subtitle: oldestReview == null
              ? null
              : 'Oldest from ${Formatters.date(oldestReview)}',
          onTap: () => context.go(AppRoutes.logbook),
        ),
      for (final internship in notVisited.take(4))
        _AttentionItem(
          icon: Icons.person_pin_circle_outlined,
          tone: AppTone.warning,
          title: '${internship.studentName} hasn’t been visited',
          subtitle: internship.companyName,
          onTap: () => context.push(
            AppRoutes.lecturerStudentDetail(internship.internshipId),
          ),
        ),
    ];

    if (items.isEmpty) {
      return AppEmptyState(
        compact: true,
        icon: Icons.task_alt_rounded,
        tone: AppTone.success,
        title: 'You’re all caught up',
        message: hasStudents
            ? 'No entries waiting and every active student has been visited.'
            : 'You’ll see logbook entries and visits due here once students '
                  'are assigned to you.',
      );
    }
    return Column(children: items);
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.icon,
    required this.tone,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final AppTone tone;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: tone.foreground),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
    );
  }
}
