import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Coordinator reports (PRD §18 "Reports"; §21 "Reports can be generated
/// without relying on paper records or spreadsheets").
///
/// Plain summaries and tables only — the PRD explicitly moves interactive
/// charts and analytics dashboards to a later version. Everything here is
/// derived from the shared coordinator overview, so it costs no extra
/// reads beyond what the Students and Lecturers screens already loaded.
///
/// Rendered inside the coordinator app shell, which supplies the scaffold.
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
      loading: () => const AppLoading(message: 'Preparing reports...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load reports. Please try again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.students.isEmpty) {
          return const AppEmptyState(
            title: 'Nothing to Report Yet',
            message: 'Reports fill in once students register and submit placements.',
          );
        }

        final students = overview.students
            .where((s) => _department == null || s.department == _department)
            .toList();
        final rows = [
          for (final student in students)
            if (overview.internshipFor(student.uid) case final internship?)
              if (CoordinatorOverview.trackedStatuses.contains(internship.status))
                (student: student, internship: internship),
        ];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _department,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(child: Text('All departments')),
                  for (final department in overview.departments)
                    DropdownMenuItem<String?>(
                      value: department,
                      child: Text(department, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _department = value),
              ),
              const SectionHeader('Placement summary'),
              _PlacementSummary(overview: overview, students: students),
              const SectionHeader('Supervision coverage'),
              _SupervisionCoverage(overview: overview, rows: rows),
              SectionHeader('Student progress (${rows.length})'),
              if (rows.isEmpty)
                const AppCard(
                  child: Text('No students have started supervision yet.'),
                )
              else
                _StudentProgressTable(overview: overview, rows: rows),
              const SectionHeader('Lecturer workload'),
              _LecturerWorkloadTable(overview: overview),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Figures are live from the database as of when this page '
                'loaded. Pull down to refresh.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

typedef _Row = ({UserModel student, InternshipModel internship});

class _PlacementSummary extends StatelessWidget {
  const _PlacementSummary({required this.overview, required this.students});

  final CoordinatorOverview overview;
  final List<UserModel> students;

  @override
  Widget build(BuildContext context) {
    final counts = <InternshipStatus?, int>{};
    for (final student in students) {
      final status = overview.internshipFor(student.uid)?.status;
      counts[status] = (counts[status] ?? 0) + 1;
    }

    const shown = <InternshipStatus?>[
      null,
      InternshipStatus.pendingReview,
      InternshipStatus.approved,
      InternshipStatus.assigned,
      InternshipStatus.active,
      InternshipStatus.completed,
      InternshipStatus.rejected,
    ];

    // Two tiles per row on a phone, four on a laptop, each filling its
    // share of the width so rows line up without a ragged gap.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatTile(label: 'Students', value: students.length, width: tileWidth),
            for (final status in shown)
              _StatTile(
                label: placementStatusLabel(status).$1,
                value: counts[status] ?? 0,
                width: tileWidth,
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      ),
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
        .where((row) => overview.progressFor(row.internship.internshipId).visits == 0)
        .toList();
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.isEmpty
                ? 'No internships are active right now.'
                : '${active.length - unvisited.length} of ${active.length} '
                      'active students have had at least one supervision visit.',
            style: textTheme.bodyMedium,
          ),
          if (unvisited.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Not yet visited:',
              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            for (final row in unvisited)
              Text(
                '• ${row.internship.studentName} — ${row.internship.companyName}'
                ' (${row.internship.lecturerName ?? 'no lecturer'})',
                style: textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

/// Tables scroll sideways on a phone rather than squashing their columns.
class _ScrollableTable extends StatelessWidget {
  const _ScrollableTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AppSpacing.md,
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          columns: [for (final column in columns) DataColumn(label: Text(column))],
          rows: [
            for (final row in rows)
              DataRow(cells: [for (final cell in row) DataCell(Text(cell))]),
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
    return _ScrollableTable(
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
    final lecturers = overview.activeLecturers;
    if (lecturers.isEmpty) {
      return const AppCard(child: Text('No approved lecturers yet.'));
    }
    return _ScrollableTable(
      columns: const ['Lecturer', 'Department', 'Current', 'All-time', 'Visits'],
      rows: [
        for (final lecturer in lecturers)
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
