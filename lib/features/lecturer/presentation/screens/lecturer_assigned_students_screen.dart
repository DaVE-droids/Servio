import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  internship.companyName,
                  style: textTheme.titleMedium,
                ),
              ),
              AppStatusChip(
                label: internship.status.label,
                type: _chipType(internship.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(internship.companyAddress, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${internship.department} • ${internship.state}, ${internship.country}',
            style: textTheme.bodySmall,
          ),
          Text(
            'Student ID: ${internship.studentId}',
            style: textTheme.bodySmall,
          ),
          Text(
            'Supervisor: ${internship.companySupervisorName} • ${internship.companySupervisorPhone}',
            style: textTheme.bodySmall,
          ),
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
