import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/journey_track.dart';
import '../../../../core/widgets/person_header.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/widgets/attendance_calendar.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// One student in full: profile, placement, progress, attendance, and —
/// when the internship is active — the action that completes it.
///
/// Takes only the student's ID (from the URL) and looks the rest up in the
/// shared overview, so a browser refresh on this page reloads it correctly.
class CoordinatorStudentDetailScreen extends ConsumerWidget {
  /// Creates the student detail screen.
  const CoordinatorStudentDetailScreen({required this.studentId, super.key});

  /// The student's UID.
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(coordinatorOverviewProvider)
        .when(
          loading: () => const AppLoading(layout: AppLoadingLayout.detail),
          error: (error, stackTrace) => AppErrorState(
            message:
                'This student couldn’t be loaded. Check your connection '
                'and try again.',
            onRetry: () => ref.invalidate(coordinatorOverviewProvider),
          ),
          data: (overview) {
            final student = overview.students
                .where((student) => student.uid == studentId)
                .firstOrNull;
            if (student == null) {
              return const AppEmptyState(
                icon: Icons.person_off_outlined,
                title: 'Student not found',
                message: 'This account may have been removed.',
              );
            }
            return _Body(
              overview: overview,
              student: student,
              internship: overview.internshipFor(student.uid),
            );
          },
        );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.overview,
    required this.student,
    required this.internship,
  });

  final CoordinatorOverview overview;
  final UserModel student;
  final InternshipModel? internship;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  var _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final internship = widget.internship;
    final name = '${student.firstName} ${student.lastName}';
    final isTracked =
        internship != null &&
        CoordinatorOverview.trackedStatuses.contains(internship.status);
    final progress = internship == null
        ? null
        : widget.overview.progressFor(internship.internshipId);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(coordinatorOverviewProvider)
          ..invalidate(studentAttendanceProvider(student.uid));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ResponsiveColumns(
            primary: [
              PersonHeader(
                name: name,
                photoUrl: student.profilePhotoUrl,
                tags: [student.matricNumber ?? '', student.department],
                status: PlacementStatusChip(status: internship?.status),
                footer: JourneyTrack(status: internship?.status),
              ),
              SectionCard(
                title: 'Profile',
                child: InfoPanel(
                  rows: [
                    InfoRow('Email', student.email, icon: Icons.mail_outline),
                    InfoRow(
                      'Phone',
                      student.phoneNumber ?? '—',
                      icon: Icons.phone_outlined,
                    ),
                    InfoRow(
                      'Faculty',
                      student.faculty ?? '—',
                      icon: Icons.account_balance_outlined,
                    ),
                    InfoRow(
                      'Joined',
                      Formatters.date(student.createdAt),
                      icon: Icons.event_outlined,
                    ),
                  ],
                ),
              ),
            ],
            secondary: [
              if (internship == null)
                const AppCard(
                  child: AppEmptyState(
                    compact: true,
                    icon: Icons.work_outline,
                    title: 'No placement yet',
                    message:
                        'This student hasn’t submitted where they’ll do their '
                        'placement.',
                  ),
                )
              else ...[
                if (isTracked && progress != null)
                  StatGrid(
                    maxColumns: 3,
                    children: [
                      StatTile(
                        value: '${progress.attendanceDays}',
                        label: 'Days attended',
                        icon: Icons.event_available_outlined,
                        tone: AppTone.sky,
                        highlighted: true,
                      ),
                      StatTile(
                        value:
                            '${progress.logbookApproved}/${progress.logbookEntries}',
                        label: 'Logbook approved',
                        icon: Icons.menu_book_outlined,
                        tone: AppTone.blush,
                      ),
                      StatTile(
                        value: '${progress.visits}',
                        label: 'Supervision visits',
                        icon: Icons.person_pin_circle_outlined,
                        tone:
                            progress.visits == 0 &&
                                internship.status == InternshipStatus.active
                            ? AppTone.warning
                            : AppTone.ink,
                      ),
                    ],
                  ),
                SectionCard(
                  title: 'Placement',
                  child: InfoPanel(
                    rows: [
                      InfoRow(
                        'Company',
                        internship.companyName,
                        icon: Icons.apartment_outlined,
                      ),
                      InfoRow(
                        'Address',
                        internship.companyAddress,
                        icon: Icons.place_outlined,
                      ),
                      InfoRow(
                        'Supervisor',
                        '${internship.companySupervisorName} · '
                            '${internship.companySupervisorPhone}',
                        icon: Icons.badge_outlined,
                      ),
                      InfoRow(
                        'Dates',
                        Formatters.dateRange(
                          internship.startDate,
                          internship.endDate,
                        ),
                        icon: Icons.date_range_outlined,
                      ),
                      InfoRow(
                        'Lecturer',
                        internship.lecturerName ?? 'Not assigned',
                        icon: Icons.school_outlined,
                      ),
                      InfoRow(
                        'Submitted',
                        Formatters.date(internship.submittedAt),
                        icon: Icons.outbox_outlined,
                      ),
                      if (internship.completedAt != null)
                        InfoRow(
                          'Completed',
                          Formatters.date(internship.completedAt),
                          icon: Icons.verified_outlined,
                        ),
                    ],
                  ),
                ),
                if (isTracked)
                  SectionCard(
                    title: 'Attendance',
                    child: ref
                        .watch(studentAttendanceProvider(student.uid))
                        .when(
                          loading: () =>
                              const Shimmer(child: SkeletonBox(height: 300)),
                          error: (error, stackTrace) => const Text(
                            'Attendance couldn’t be loaded. Pull down to try '
                            'again.',
                          ),
                          data: (records) => AttendanceCalendar(
                            records: records,
                            since:
                                internship.activatedAt ?? internship.startDate,
                          ),
                        ),
                  ),
                if (internship.status == InternshipStatus.active)
                  SectionCard(
                    title: 'Finish this internship',
                    subtitle:
                        'Completing ends the placement: the student can no '
                        'longer check in or add logbook entries. Their records '
                        'are kept.',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: 'Mark internship completed',
                        icon: Icons.verified_outlined,
                        expand: false,
                        isLoading: _isCompleting,
                        onPressed: () => _confirmComplete(internship),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _confirmComplete(InternshipModel internship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        icon: Icons.verified_outlined,
        title: 'Complete this internship?',
        message:
            '${internship.studentName}’s placement at ${internship.companyName} '
            'will be marked completed and they’ll be notified. This can’t be '
            'undone from the app.',
        confirmLabel: 'Mark completed',
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
