import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/journey_track.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Which students the list shows.
enum _StudentFilter {
  all('All'),
  awaiting('Awaiting action'),
  active('Active'),
  completed('Completed'),
  none('No placement');

  const _StudentFilter(this.label);

  final String label;

  bool matches(InternshipStatus? status) => switch (this) {
    all => true,
    awaiting =>
      status == InternshipStatus.pendingReview ||
          status == InternshipStatus.approved ||
          status == InternshipStatus.assigned,
    active => status == InternshipStatus.active,
    completed => status == InternshipStatus.completed,
    none => status == null || status == InternshipStatus.rejected,
  };
}

/// Every registered student, their placement status, and how their
/// internship is going (PRD §18 "Student management"). A table on wide
/// screens, cards on phones.
class CoordinatorStudentsScreen extends ConsumerStatefulWidget {
  /// Creates the students screen.
  const CoordinatorStudentsScreen({super.key});

  @override
  ConsumerState<CoordinatorStudentsScreen> createState() =>
      _CoordinatorStudentsScreenState();
}

class _CoordinatorStudentsScreenState
    extends ConsumerState<CoordinatorStudentsScreen> {
  var _query = '';
  var _filter = _StudentFilter.all;

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return overviewValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Students couldn’t be loaded. Check your connection and try '
            'again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.students.isEmpty) {
          return const AppEmptyState(
            icon: Icons.school_outlined,
            title: 'No students yet',
            message: 'Students appear here as soon as they create an account.',
          );
        }

        final matches = overview.students.where((student) {
          final status = overview.internshipFor(student.uid)?.status;
          if (!_filter.matches(status)) {
            return false;
          }
          if (_query.isEmpty) {
            return true;
          }
          return [
            student.firstName,
            student.lastName,
            student.matricNumber ?? '',
            student.department,
            overview.internshipFor(student.uid)?.companyName ?? '',
          ].join(' ').toLowerCase().contains(_query);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText:
                      'Search by name, matric number, department, or company',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _StudentFilter.values) ...[
                      ChoiceChip(
                        label: Text(
                          '${filter.label} · ${overview.students.where((s) => filter.matches(overview.internshipFor(s.uid)?.status)).length}',
                        ),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (matches.isEmpty)
                const AppEmptyState(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: 'No students match',
                  message: 'Try a different search or filter.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 860
                      ? _StudentTable(overview: overview, students: matches)
                      : Column(
                          children: [
                            for (final student in matches) ...[
                              _StudentCard(
                                overview: overview,
                                student: student,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

/// The wide-screen table, after the sample's student list.
class _StudentTable extends StatelessWidget {
  const _StudentTable({required this.overview, required this.students});

  final CoordinatorOverview overview;
  final List<UserModel> students;

  static const _flex = [5, 4, 4, 3, 3];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget header(String label, int flex) => Expanded(
      flex: flex,
      child: Text(label.toUpperCase(), style: textTheme.labelSmall),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                header('Student', _flex[0]),
                header('Placement', _flex[1]),
                header('Lecturer', _flex[2]),
                header('Status', _flex[3]),
                header('Progress', _flex[4]),
              ],
            ),
          ),
          const Divider(),
          for (var i = 0; i < students.length; i++) ...[
            if (i > 0) const Divider(indent: 20, endIndent: 20),
            _StudentRow(overview: overview, student: students[i]),
          ],
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.overview, required this.student});

  final CoordinatorOverview overview;
  final UserModel student;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final internship = overview.internshipFor(student.uid);
    final name = '${student.firstName} ${student.lastName}';
    const flex = _StudentTable._flex;
    final progress = internship == null
        ? null
        : overview.progress[internship.internshipId];

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.coordinatorStudentDetail(student.uid)),
      hoverColor: AppColors.mist,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: flex[0],
              child: Row(
                children: [
                  AppAvatar(
                    name: name,
                    photoUrl: student.profilePhotoUrl,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                        Text(
                          [
                            if ((student.matricNumber ?? '').isNotEmpty)
                              student.matricNumber!,
                            student.department,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: flex[1],
              child: Text(
                internship?.companyName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: flex[2],
              child: Text(
                internship?.lecturerName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: flex[3],
              child: Align(
                alignment: Alignment.centerLeft,
                child: PlacementStatusChip(status: internship?.status),
              ),
            ),
            Expanded(
              flex: flex[4],
              child: progress == null
                  ? Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: JourneyTrack.compact(status: internship?.status),
                    )
                  : Text(
                      '${progress.attendanceDays} d · '
                      '${progress.logbookApproved}/${progress.logbookEntries} log · '
                      '${progress.visits} v',
                      style: textTheme.bodySmall,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.overview, required this.student});

  final CoordinatorOverview overview;
  final UserModel student;

  @override
  Widget build(BuildContext context) {
    final internship = overview.internshipFor(student.uid);
    final textTheme = Theme.of(context).textTheme;
    final name = '${student.firstName} ${student.lastName}';
    final isTracked =
        internship != null &&
        CoordinatorOverview.trackedStatuses.contains(internship.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () =>
          context.push(AppRoutes.coordinatorStudentDetail(student.uid)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(
                name: name,
                photoUrl: student.profilePhotoUrl,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if ((student.matricNumber ?? '').isNotEmpty)
                          student.matricNumber!,
                        student.department,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PlacementStatusChip(status: internship?.status),
            ],
          ),
          if (internship != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              internship.lecturerName == null
                  ? internship.companyName
                  : '${internship.companyName} · ${internship.lecturerName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ],
          if (isTracked) ...[
            const SizedBox(height: AppSpacing.xs),
            ProgressLine(overview.progressFor(internship.internshipId)),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            JourneyTrack.compact(status: internship?.status),
          ],
        ],
      ),
    );
  }
}
