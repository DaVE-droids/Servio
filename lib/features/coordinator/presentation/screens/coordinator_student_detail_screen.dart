import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../reports/data/models/internship_progress.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// One student in full: profile, placement, progress, and — when the
/// internship is active — the action that completes it.
///
/// Takes only the student's ID (from the URL) and looks the rest up in the
/// shared overview. That way a browser refresh on this page reloads it
/// correctly, where passing the student object through navigation would
/// arrive empty after a reload.
class CoordinatorStudentDetailScreen extends ConsumerStatefulWidget {
  /// Creates the student detail screen.
  const CoordinatorStudentDetailScreen({required this.studentId, super.key});

  /// The student's UID.
  final String studentId;

  @override
  ConsumerState<CoordinatorStudentDetailScreen> createState() =>
      _CoordinatorStudentDetailScreenState();
}

class _CoordinatorStudentDetailScreenState
    extends ConsumerState<CoordinatorStudentDetailScreen> {
  var _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: overviewValue.when(
        loading: () => const AppLoading(message: 'Loading student...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load this student. Please try again.',
          onRetry: () => ref.invalidate(coordinatorOverviewProvider),
        ),
        data: (overview) {
          final matches = overview.students.where(
            (student) => student.uid == widget.studentId,
          );
          if (matches.isEmpty) {
            return const AppErrorState(message: 'This student could not be found.');
          }
          return _buildBody(context, overview, matches.first.uid);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CoordinatorOverview overview,
    String studentId,
  ) {
    final student = overview.students.firstWhere((s) => s.uid == studentId);
    final internship = overview.internshipFor(studentId);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              '${student.firstName} ${student.lastName}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: PlacementStatusChip(status: internship?.status),
            ),
            const SectionHeader('Profile'),
            AppCard(
              child: Column(
                children: [
                  InfoRow('Matric number', student.matricNumber ?? '—'),
                  InfoRow('Department', student.department),
                  InfoRow('Faculty', student.faculty ?? '—'),
                  InfoRow('Email', student.email),
                  InfoRow('Phone', student.phoneNumber ?? '—'),
                ],
              ),
            ),
            const SectionHeader('Placement'),
            if (internship == null)
              const AppCard(
                child: Text('This student has not submitted a placement yet.'),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    InfoRow('Company', internship.companyName),
                    InfoRow('Address', internship.companyAddress),
                    InfoRow(
                      'Location',
                      [internship.state, internship.country]
                          .where((part) => part.isNotEmpty)
                          .join(', '),
                    ),
                    InfoRow(
                      'Supervisor',
                      '${internship.companySupervisorName} '
                          '(${internship.companySupervisorPhone})',
                    ),
                    InfoRow(
                      'Dates',
                      '${shortDate(internship.startDate)} to '
                          '${shortDate(internship.endDate)}',
                    ),
                    InfoRow('Lecturer', internship.lecturerName ?? 'Not assigned'),
                    InfoRow('Submitted', shortDate(internship.submittedAt)),
                    if (internship.activatedAt != null)
                      InfoRow('Started', shortDate(internship.activatedAt)),
                    if (internship.completedAt != null)
                      InfoRow('Completed', shortDate(internship.completedAt)),
                  ],
                ),
              ),
            if (internship != null &&
                CoordinatorOverview.trackedStatuses.contains(internship.status)) ...[
              const SectionHeader('Progress'),
              AppCard(
                child: _ProgressDetail(
                  progress: overview.progressFor(internship.internshipId),
                ),
              ),
            ],
            if (internship?.status == InternshipStatus.active) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Mark Internship Completed',
                isLoading: _isCompleting,
                onPressed: () => _confirmComplete(internship!),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Completing ends the placement: the student can no longer '
                'check in or add logbook entries. Their records are kept.',
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmComplete(InternshipModel internship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Complete this internship?',
        message:
            "${internship.studentName}'s placement at ${internship.companyName} "
            'will be marked completed. This cannot be undone from the app.',
        confirmLabel: 'Mark Completed',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isCompleting = true);
    final result = await ref
        .read(coordinatorActionsProvider)
        .completeInternship(internship);
    if (!mounted) {
      return;
    }
    setState(() => _isCompleting = false);

    final message = switch (result) {
      Success<void>() => 'Internship marked as completed.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProgressDetail extends StatelessWidget {
  const _ProgressDetail({required this.progress});

  final InternshipProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoRow(
          'Attendance',
          '${progress.attendanceDays} day${progress.attendanceDays == 1 ? '' : 's'} checked in',
        ),
        InfoRow(
          'Logbook',
          '${progress.logbookEntries} ${progress.logbookEntries == 1 ? 'entry' : 'entries'}, '
          '${progress.logbookApproved} approved',
        ),
        InfoRow(
          'Visits',
          '${progress.visits} supervision visit${progress.visits == 1 ? '' : 's'}',
        ),
      ],
    );
  }
}
