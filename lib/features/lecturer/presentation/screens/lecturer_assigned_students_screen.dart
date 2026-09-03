import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../supervision/presentation/providers/supervision_providers.dart';
import '../providers/assigned_students_provider.dart';

/// Lists placements currently assigned to the signed-in lecturer.
class LecturerAssignedStudentsScreen extends ConsumerWidget {
  /// Creates the lecturer assigned-students screen.
  const LecturerAssignedStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStudentsValue = ref.watch(assignedStudentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Students')),
      body: assignedStudentsValue.when(
        loading: () => const AppLoading(message: 'Loading students...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load your assigned students. Please try again.',
          onRetry: () => ref.invalidate(assignedStudentsProvider),
        ),
        data: (internships) {
          if (internships.isEmpty) {
            return const AppEmptyState(
              title: 'No Assigned Students',
              message:
                  'Once a coordinator assigns a placement to you, it will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(assignedStudentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: internships.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _AssignedStudentCard(internship: internships[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AssignedStudentCard extends ConsumerWidget {
  const _AssignedStudentCard({required this.internship});

  final InternshipModel internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.studentDetail, extra: internship),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _studentTitle(internship),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppStatusChip(
                    label: internship.status.label,
                    type: _chipType(internship.status),
                  ),
                ],
              ),
              if (internship.studentMatricNumber.isNotEmpty)
                Text(
                  internship.studentMatricNumber,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.xxs),
              Text(internship.companyAddress, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${internship.department} • ${internship.state}, ${internship.country}',
                style: textTheme.bodySmall,
              ),
              Text(internship.companyName, style: textTheme.bodySmall),
              Text(
                'Supervisor: ${internship.companySupervisorName} • ${internship.companySupervisorPhone}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _VisitIndicator(internshipId: internship.internshipId),
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
      ),
    );
  }

  AppStatusChipType _chipType(InternshipStatus status) {
    return switch (status) {
      InternshipStatus.assigned ||
      InternshipStatus.active ||
      InternshipStatus.completed => AppStatusChipType.success,
      InternshipStatus.pendingReview => AppStatusChipType.warning,
      InternshipStatus.rejected => AppStatusChipType.error,
      InternshipStatus.approved => AppStatusChipType.info,
      InternshipStatus.draft || InternshipStatus.archived =>
        AppStatusChipType.neutral,
    };
  }
}

/// Shows at a glance whether this student has been visited, so a lecturer
/// scanning the list can spot who still needs a visit without opening each
/// student in turn.
class _VisitIndicator extends ConsumerWidget {
  const _VisitIndicator({required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastVisits = ref.watch(lastVisitByInternshipProvider);
    final textTheme = Theme.of(context).textTheme;

    return lastVisits.when(
      loading: () => Text('Checking visits...', style: textTheme.bodySmall),
      error: (error, stackTrace) =>
          Text('Visit status unavailable', style: textTheme.bodySmall),
      data: (visits) {
        final lastVisit = visits[internshipId];
        if (lastVisit == null) {
          return Row(
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Not visited yet',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'Last visited ${_formatDate(lastVisit)}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.success),
            ),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

/// The card's headline: the student's name, falling back to their matric
/// number and then their raw ID for placements submitted before the name
/// was denormalized onto `internships`. The matric number renders on its
/// own line rather than being appended here, so the headline always fits
/// on one line beside the status chip.
String _studentTitle(InternshipModel internship) {
  if (internship.studentName.isNotEmpty) {
    return internship.studentName;
  }
  if (internship.studentMatricNumber.isNotEmpty) {
    return internship.studentMatricNumber;
  }
  return 'Student ${internship.studentId}';
}
