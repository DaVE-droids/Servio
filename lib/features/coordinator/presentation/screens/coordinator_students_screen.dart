import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// Coordinator student management: every registered student, their
/// placement status, and how their internship is going (PRD §18
/// "Student management").
///
/// Rendered inside the coordinator app shell, which supplies the scaffold.
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

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return overviewValue.when(
      loading: () => const AppLoading(message: 'Loading students...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load students. Please try again.',
        onRetry: () => ref.invalidate(coordinatorOverviewProvider),
      ),
      data: (overview) {
        if (overview.students.isEmpty) {
          return const AppEmptyState(
            title: 'No Students Yet',
            message: 'Students appear here as soon as they create an account.',
          );
        }

        final matches = overview.students.where((student) {
          if (_query.isEmpty) {
            return true;
          }
          final haystack = [
            student.firstName,
            student.lastName,
            student.matricNumber ?? '',
            student.department,
            overview.internshipFor(student.uid)?.companyName ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(_query);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: matches.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return TextField(
                  decoration: InputDecoration(
                    labelText: 'Search students',
                    hintText: 'Name, matric number, department, or company',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    helperText:
                        '${matches.length} of ${overview.students.length} students',
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                );
              }
              return _StudentCard(
                overview: overview,
                studentIndex: overview.students.indexOf(matches[index - 1]),
              );
            },
          ),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.overview, required this.studentIndex});

  final CoordinatorOverview overview;
  final int studentIndex;

  @override
  Widget build(BuildContext context) {
    final student = overview.students[studentIndex];
    final internship = overview.internshipFor(student.uid);
    final textTheme = Theme.of(context).textTheme;
    final isTracked =
        internship != null &&
        CoordinatorOverview.trackedStatuses.contains(internship.status);

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.coordinatorStudentDetail(student.uid)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${student.firstName} ${student.lastName}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PlacementStatusChip(status: internship?.status),
                ],
              ),
              Text(
                [
                  if ((student.matricNumber ?? '').isNotEmpty)
                    student.matricNumber!,
                  student.department,
                ].join(' · '),
                style: textTheme.bodySmall,
              ),
              if (internship != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  internship.lecturerName == null
                      ? internship.companyName
                      : '${internship.companyName} · ${internship.lecturerName}',
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isTracked) ...[
                const SizedBox(height: AppSpacing.xs),
                ProgressLine(overview.progressFor(internship.internshipId)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
