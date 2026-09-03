import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../../logbook/presentation/providers/logbook_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../supervision/presentation/providers/supervision_providers.dart';

/// Lecturer screen showing full detail for one assigned student (FR-SUP-002):
/// student info, placement info, attendance/logbook summaries, company
/// location, and contact info, plus Navigate (FR-SUP-003) and a way to
/// submit a visit report (FR-SUP-004).
class LecturerStudentDetailScreen extends ConsumerStatefulWidget {
  /// Creates the lecturer student detail screen.
  const LecturerStudentDetailScreen({required this.internship, super.key});

  /// The internship being viewed.
  final InternshipModel internship;

  @override
  ConsumerState<LecturerStudentDetailScreen> createState() =>
      _LecturerStudentDetailScreenState();
}

class _LecturerStudentDetailScreenState
    extends ConsumerState<LecturerStudentDetailScreen> {
  late Future<Result<UserModel>> _studentFuture;
  late Future<Result<List<AttendanceModel>>> _attendanceFuture;
  late Future<Result<List<LogbookEntryModel>>> _logbookFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Starts (or restarts) the lookups this screen owns. Retry has to build
  /// new futures — a bare `setState` would just re-render the same
  /// already-settled ones and appear to do nothing. Visit history isn't
  /// here: it comes from the shared [lecturerReportsProvider], so it also
  /// refreshes when a new report is submitted.
  void _load() {
    _studentFuture = ref
        .read(getCurrentUserUseCaseProvider)
        .call(widget.internship.studentId);
    _attendanceFuture = ref
        .read(getAttendanceHistoryUseCaseProvider)
        .call(widget.internship.studentId);
    _logbookFuture = ref
        .read(getStudentEntriesUseCaseProvider)
        .call(widget.internship.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final internship = widget.internship;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Detail')),
      body: FutureBuilder<Result<UserModel>>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AppLoading(message: 'Loading student...');
          }
          return switch (snapshot.data!) {
            Failure<UserModel>() => AppErrorState(
              message: 'Unable to load this student. Please try again.',
              onRetry: () => setState(_load),
            ),
            Success<UserModel>(:final data) => _buildContent(
              context,
              internship,
              data,
            ),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    InternshipModel internship,
    UserModel student,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(label: 'Name', value: '${student.firstName} ${student.lastName}'),
              _InfoRow(
                label: 'Matric Number',
                value: student.matricNumber ?? 'Not set',
              ),
              _InfoRow(label: 'Department', value: student.department),
              _InfoRow(label: 'Email', value: student.email),
              _InfoRow(
                label: 'Phone',
                value: student.phoneNumber ?? 'Not set',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Placement Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(label: 'Company', value: internship.companyName),
              _InfoRow(label: 'Status', value: internship.status.label),
              _InfoRow(
                label: 'State / Country',
                value: '${internship.state}, ${internship.country}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Company Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(internship.companyAddress),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Navigate',
                variant: AppButtonVariant.secondary,
                onPressed: () => ref
                    .read(mapsServiceProvider)
                    .launchNavigation(
                      latitude: internship.companyLatitude,
                      longitude: internship.companyLongitude,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                label: 'Student Phone',
                value: student.phoneNumber ?? 'Not set',
              ),
              _InfoRow(
                label: 'Company Supervisor',
                value: internship.companySupervisorName,
              ),
              _InfoRow(
                label: 'Supervisor Phone',
                value: internship.companySupervisorPhone,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<Result<List<AttendanceModel>>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  }
                  return switch (snapshot.data!) {
                    Failure<List<AttendanceModel>>() => const Text(
                      'Unable to load attendance summary.',
                    ),
                    Success<List<AttendanceModel>>(:final data) => Text(
                      data.isEmpty
                          ? 'No attendance recorded yet.'
                          : '${data.length} record(s) — most recent: ${_formatDate(data.first.date)}',
                    ),
                  };
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logbook Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<Result<List<LogbookEntryModel>>>(
                future: _logbookFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  }
                  return switch (snapshot.data!) {
                    Failure<List<LogbookEntryModel>>() => const Text(
                      'Unable to load logbook summary.',
                    ),
                    Success<List<LogbookEntryModel>>(:final data) => Text(
                      data.isEmpty
                          ? 'No logbook entries yet.'
                          : '${data.length} entr${data.length == 1 ? 'y' : 'ies'} — most recent: ${_formatDate(data.first.date)}',
                    ),
                  };
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visit History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Consumer(
                builder: (context, ref, child) {
                  final reportsValue = ref.watch(lecturerReportsProvider);
                  return reportsValue.when(
                    loading: () => const Text('Loading...'),
                    error: (error, stackTrace) =>
                        const Text('Unable to load visit history.'),
                    data: (reports) {
                      final visits = reports
                          .where(
                            (report) =>
                                report.internshipId ==
                                internship.internshipId,
                          )
                          .toList();
                      if (visits.isEmpty) {
                        return const Text('No visits recorded yet.');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: visits
                            .map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: Text(
                                  '${_formatDate(report.visitDate)} — Rating: ${report.rating}/5',
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Submit Visit Report',
          onPressed: () => context.push(
            AppRoutes.visitReports,
            extra: (internship, student),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
