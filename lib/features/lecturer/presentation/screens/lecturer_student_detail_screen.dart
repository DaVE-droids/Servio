import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/journey_track.dart';
import '../../../../core/widgets/person_header.dart';
import '../../../../core/widgets/placement_status_chip.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/widgets/attendance_calendar.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../supervision/data/models/supervision_report_model.dart';
import '../../../supervision/presentation/providers/supervision_providers.dart';
import '../providers/assigned_students_provider.dart';
import '../widgets/assigned_internship_builder.dart';

/// Everything a lecturer needs about one assigned student (FR-SUP-002):
/// who they are, where they're placed, how their attendance and logbook
/// are going, and their visit history — with Navigate (FR-SUP-003) and a
/// new visit report (FR-SUP-004) one tap away.
class LecturerStudentDetailScreen extends ConsumerWidget {
  /// Creates the lecturer student detail screen.
  const LecturerStudentDetailScreen({required this.internshipId, super.key});

  /// The placement being viewed, from the URL.
  final String internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AssignedInternshipBuilder(
      internshipId: internshipId,
      builder: (context, internship) => _Content(internship: internship),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.internship});

  final InternshipModel internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(userProfileProvider(internship.studentId)).value;
    final attendance = ref.watch(
      studentAttendanceProvider(internship.studentId),
    );
    final progress = ref
        .watch(internshipProgressProvider(internship.internshipId))
        .value;
    final visits = ref
        .watch(lecturerReportsProvider)
        .whenData(
          (reports) => reports
              .where((report) => report.internshipId == internship.internshipId)
              .toList(),
        );
    final canVisit =
        internship.status == InternshipStatus.active ||
        internship.status == InternshipStatus.assigned;

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(assignedStudentsProvider)
          ..invalidate(userProfileProvider(internship.studentId))
          ..invalidate(studentAttendanceProvider(internship.studentId))
          ..invalidate(internshipProgressProvider(internship.internshipId))
          ..invalidate(lecturerReportsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ResponsiveColumns(
            primary: [
              PersonHeader(
                name: internship.studentName.isEmpty
                    ? 'Student'
                    : internship.studentName,
                photoUrl: student?.profilePhotoUrl,
                tags: [internship.studentMatricNumber, internship.department],
                status: PlacementStatusChip(status: internship.status),
                footer: Column(
                  children: [
                    JourneyTrack(status: internship.status),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Navigate',
                            icon: Icons.near_me_outlined,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => ref
                                .read(mapsServiceProvider)
                                .launchNavigation(
                                  latitude: internship.companyLatitude,
                                  longitude: internship.companyLongitude,
                                ),
                          ),
                        ),
                        if (canVisit) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppButton(
                              label: 'Log visit',
                              icon: Icons.add_rounded,
                              onPressed: () => context.push(
                                AppRoutes.lecturerVisitReport(
                                  internship.internshipId,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Contact',
                child: InfoPanel(
                  rows: [
                    InfoRow(
                      'Phone',
                      student?.phoneNumber ?? '—',
                      icon: Icons.phone_outlined,
                    ),
                    InfoRow(
                      'Email',
                      student?.email ?? '—',
                      icon: Icons.mail_outline,
                    ),
                    InfoRow(
                      'Supervisor',
                      internship.companySupervisorName,
                      icon: Icons.badge_outlined,
                    ),
                    InfoRow(
                      'Supervisor phone',
                      internship.companySupervisorPhone,
                      icon: Icons.call_outlined,
                    ),
                  ],
                ),
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
                      'Location',
                      [
                        internship.state,
                        internship.country,
                      ].where((part) => part.isNotEmpty).join(', '),
                      icon: Icons.map_outlined,
                    ),
                    InfoRow(
                      'Dates',
                      Formatters.dateRange(
                        internship.startDate,
                        internship.endDate,
                      ),
                      icon: Icons.date_range_outlined,
                    ),
                  ],
                ),
              ),
            ],
            secondary: [
              StatGrid(
                maxColumns: 3,
                children: [
                  StatTile(
                    value: progress == null
                        ? '–'
                        : '${progress.attendanceDays}',
                    label: 'Days attended',
                    icon: Icons.event_available_outlined,
                    tone: AppTone.sky,
                    highlighted: true,
                  ),
                  StatTile(
                    value: progress == null
                        ? '–'
                        : '${progress.logbookApproved}/${progress.logbookEntries}',
                    label: 'Logbook approved',
                    icon: Icons.menu_book_outlined,
                    tone: AppTone.blush,
                  ),
                  StatTile(
                    value: progress == null ? '–' : '${progress.visits}',
                    label: 'Visits logged',
                    icon: Icons.person_pin_circle_outlined,
                  ),
                ],
              ),
              SectionCard(
                title: 'Attendance',
                child: attendance.when(
                  loading: () => const Shimmer(child: SkeletonBox(height: 300)),
                  error: (error, stackTrace) => const Text(
                    'Attendance couldn’t be loaded. Pull down to try again.',
                  ),
                  data: (records) => AttendanceCalendar(
                    records: records,
                    since: internship.activatedAt ?? internship.startDate,
                  ),
                ),
              ),
              SectionCard(
                title: 'Visit history',
                child: visits.when(
                  loading: () => const Shimmer(child: SkeletonBox(height: 80)),
                  error: (error, stackTrace) =>
                      const Text('Visits couldn’t be loaded.'),
                  data: (reports) => reports.isEmpty
                      ? const AppEmptyState(
                          compact: true,
                          icon: Icons.person_pin_circle_outlined,
                          title: 'No visits yet',
                          message:
                              'Reports you log for this student will be '
                              'listed here.',
                        )
                      : Column(
                          children: [
                            for (final report in reports)
                              _VisitTile(report: report),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.report});

  final SupervisionReportModel report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${report.visitDate.toLocal().day}',
                  style: textTheme.titleMedium?.copyWith(color: AppColors.ink),
                ),
                Text(
                  Formatters.month(report.visitDate.toLocal().month),
                  style: textTheme.labelSmall?.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= report.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: i <= report.rating
                            ? AppColors.warning
                            : AppColors.lineStrong,
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      Formatters.time(report.visitDate),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  report.observation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
