import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Coordinator reports (PRD §18 "Reports"; §21 "Reports can be generated
/// without relying on paper records or spreadsheets").
///
/// Summaries and tables rather than an analytics dashboard, which the PRD
/// moves to a later version. Everything is derived from the shared
/// coordinator overview, so it costs no reads beyond what the Students and
/// Lecturers screens already loaded. Each table can be copied as CSV to
/// paste into a spreadsheet.
class CoordinatorReportsScreen extends ConsumerStatefulWidget {
  /// Creates the reports screen.
  const CoordinatorReportsScreen({super.key});

  @override
  ConsumerState<CoordinatorReportsScreen> createState() =>
      _CoordinatorReportsScreenState();
}

class _CoordinatorReportsScreenState
    extends ConsumerState<CoordinatorReportsScreen> {
  /// Null means "all departments".
  String? _department;

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return overviewValue.when(
      loading: () => const AppLoading(layout: AppLoadingLayout.dashboard),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Reports couldn’t be prepared. Check your connection and try '
            'again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.students.isEmpty) {
          return const AppEmptyState(
            icon: Icons.insights_outlined,
            title: 'Nothing to report yet',
            message:
                'Reports fill in once students register and submit placements.',
          );
        }

        final students = overview.students
            .where((s) => _department == null || s.department == _department)
            .toList();
        final rows = [
          for (final student in students)
            if (overview.internshipFor(student.uid) case final internship?)
              if (CoordinatorOverview.trackedStatuses.contains(
                internship.status,
              ))
                (student: student, internship: internship),
        ];
        final counts = <InternshipStatus?, int>{};
        for (final student in students) {
          final status = overview.internshipFor(student.uid)?.status;
          counts[status] = (counts[status] ?? 0) + 1;
        }
        final awaiting =
            (counts[InternshipStatus.pendingReview] ?? 0) +
            (counts[InternshipStatus.approved] ?? 0) +
            (counts[InternshipStatus.assigned] ?? 0);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live figures, as of when this page loaded.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _department,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.filter_list_rounded, size: 20),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('All departments'),
                        ),
                        for (final department in overview.departments)
                          DropdownMenuItem<String?>(
                            value: department,
                            child: Text(
                              department,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _department = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StatGrid(
                children: [
                  StatTile(
                    value: '${students.length}',
                    label: 'Students',
                    icon: Icons.school_outlined,
                    tone: AppTone.sky,
                    highlighted: true,
                  ),
                  StatTile(
                    value: '${counts[InternshipStatus.active] ?? 0}',
                    label: 'On placement now',
                    icon: Icons.work_outline,
                    tone: AppTone.sky,
                  ),
                  StatTile(
                    value: '$awaiting',
                    label: 'Awaiting your action',
                    icon: Icons.pending_actions_outlined,
                    tone: awaiting > 0 ? AppTone.warning : AppTone.ink,
                  ),
                  StatTile(
                    value: '${counts[InternshipStatus.completed] ?? 0}',
                    label: 'Completed',
                    icon: Icons.verified_outlined,
                    tone: AppTone.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'Where the cohort is',
                subtitle: 'Each student’s current placement, by journey stage.',
                child: _PipelineBar(counts: counts, total: students.length),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'Supervision coverage',
                child: _SupervisionCoverage(overview: overview, rows: rows),
              ),
              const SizedBox(height: AppSpacing.md),
              _StudentProgressTable(overview: overview, rows: rows),
              const SizedBox(height: AppSpacing.md),
              _LecturerWorkloadTable(overview: overview),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

typedef _Row = ({UserModel student, InternshipModel internship});

/// One stacked bar across the journey stages, with a legend of counts.
class _PipelineBar extends StatelessWidget {
  const _PipelineBar({required this.counts, required this.total});

  final Map<InternshipStatus?, int> counts;
  final int total;

  static const _stages = <(InternshipStatus?, String, Color)>[
    (null, 'No placement', AppColors.line),
    (InternshipStatus.pendingReview, 'Pending review', AppColors.warningSoft),
    (InternshipStatus.approved, 'Needs lecturer', AppColors.blush),
    (InternshipStatus.assigned, 'Ready to start', AppColors.skySoft),
    (InternshipStatus.active, 'Active', AppColors.sky),
    (InternshipStatus.completed, 'Completed', AppColors.ink),
    (InternshipStatus.rejected, 'Rejected', AppColors.errorSoft),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final present = _stages.where((stage) => (counts[stage.$1] ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: [
            for (final stage in present) '${counts[stage.$1]} ${stage.$2}',
          ].join(', '),
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  for (final stage in present)
                    Expanded(
                      flex: counts[stage.$1]!,
                      child: Container(
                        color: stage.$3,
                        margin: const EdgeInsets.only(right: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final stage in _stages)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: stage.$3,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppColors.lineStrong,
                        width: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(stage.$2, style: textTheme.bodySmall),
                  const SizedBox(width: 4),
                  Text(
                    '${counts[stage.$1] ?? 0}',
                    style: textTheme.titleSmall?.copyWith(
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _SupervisionCoverage extends StatelessWidget {
  const _SupervisionCoverage({required this.overview, required this.rows});

  final CoordinatorOverview overview;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final active = rows
        .where((row) => row.internship.status == InternshipStatus.active)
        .toList();
    final unvisited = active
        .where(
          (row) =>
              overview.progressFor(row.internship.internshipId).visits == 0,
        )
        .toList();
    final visited = active.length - unvisited.length;
    final textTheme = Theme.of(context).textTheme;

    if (active.isEmpty) {
      return Text(
        'No internships are active right now.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$visited',
              style: textTheme.headlineMedium?.copyWith(
                fontFeatures: AppTypography.tabular,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                'of ${active.length} active students visited at least once',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: visited / active.length,
            minHeight: 8,
            color: AppColors.ink,
            backgroundColor: AppColors.inkSoft,
          ),
        ),
        if (unvisited.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('NOT YET VISITED', style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final row in unvisited)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_pin_circle_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${row.internship.studentName} · ${row.internship.companyName}'
                      ' · ${row.internship.lecturerName ?? 'no lecturer'}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// A titled table that scrolls sideways on a phone rather than squashing
/// its columns, with a button to copy it as CSV.
class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final String emptyMessage;

  String _csv() {
    String cell(String value) {
      final needsQuotes = value.contains(RegExp(r'[",\n]'));
      final escaped = value.replaceAll('"', '""');
      return needsQuotes ? '"$escaped"' : escaped;
    }

    return [
      columns.map(cell).join(','),
      for (final row in rows) row.map(cell).join(','),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      title: title,
      subtitle: Formatters.count(rows.length, 'row'),
      trailing: rows.isEmpty
          ? null
          : TextButton.icon(
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: const Text('Copy as CSV'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _csv()));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Copied. Paste into Excel or Google Sheets.',
                      ),
                    ),
                  );
                }
              },
            ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                emptyMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: AppSpacing.lg,
                headingRowHeight: 40,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                headingTextStyle: textTheme.labelSmall,
                dataTextStyle: textTheme.bodyMedium,
                dividerThickness: 1,
                columns: [
                  for (final column in columns)
                    DataColumn(label: Text(column.toUpperCase())),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [for (final cell in row) DataCell(Text(cell))],
                    ),
                ],
              ),
            ),
    );
  }
}

class _StudentProgressTable extends StatelessWidget {
  const _StudentProgressTable({required this.overview, required this.rows});

  final CoordinatorOverview overview;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      title: 'Student progress',
      emptyMessage: 'No students have started supervision yet.',
      columns: const [
        'Student',
        'Matric',
        'Company',
        'Lecturer',
        'Status',
        'Days',
        'Logbook',
        'Visits',
      ],
      rows: [
        for (final row in rows)
          () {
            final progress = overview.progressFor(row.internship.internshipId);
            return [
              '${row.student.firstName} ${row.student.lastName}',
              row.student.matricNumber ?? '—',
              row.internship.companyName,
              row.internship.lecturerName ?? '—',
              placementStatusLabel(row.internship.status).$1,
              '${progress.attendanceDays}',
              '${progress.logbookApproved}/${progress.logbookEntries}',
              '${progress.visits}',
            ];
          }(),
      ],
    );
  }
}

class _LecturerWorkloadTable extends StatelessWidget {
  const _LecturerWorkloadTable({required this.overview});

  final CoordinatorOverview overview;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      title: 'Lecturer workload',
      emptyMessage: 'No approved lecturers yet.',
      columns: const [
        'Lecturer',
        'Department',
        'Current',
        'All-time',
        'Visits',
      ],
      rows: [
        for (final lecturer in overview.activeLecturers)
          () {
            final all = overview.allSupervisedBy(lecturer.uid);
            final visits = all.fold<int>(
              0,
              (sum, i) => sum + overview.progressFor(i.internshipId).visits,
            );
            return [
              '${lecturer.firstName} ${lecturer.lastName}',
              lecturer.department,
              '${overview.activeLoadFor(lecturer.uid).length}',
              '${all.length}',
              '$visits',
            ];
          }(),
      ],
    );
  }
}
