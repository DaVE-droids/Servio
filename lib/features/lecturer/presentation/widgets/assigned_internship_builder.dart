import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../internship/data/models/internship_model.dart';
import '../providers/assigned_students_provider.dart';

/// Finds one of the lecturer's assigned placements by the ID in the URL.
///
/// Lecturer pages used to receive the placement as an in-memory argument,
/// which vanished when the page was refreshed in a browser. Looking it up
/// in the (already loaded) assigned-students list keeps those pages
/// working after a refresh or from a bookmark — and only ever shows
/// placements that really are assigned to this lecturer.
class AssignedInternshipBuilder extends ConsumerWidget {
  /// Creates the lookup.
  const AssignedInternshipBuilder({
    required this.internshipId,
    required this.builder,
    super.key,
  });

  /// Placement to find.
  final String internshipId;

  /// Builds the page once the placement is found.
  final Widget Function(BuildContext context, InternshipModel internship)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(assignedStudentsProvider)
        .when(
          loading: () => const AppLoading(layout: AppLoadingLayout.detail),
          error: (error, stackTrace) => AppErrorState(
            message:
                'We couldn’t load this student. Check your connection '
                'and try again.',
            onRetry: () => ref.invalidate(assignedStudentsProvider),
          ),
          data: (internships) {
            for (final internship in internships) {
              if (internship.internshipId == internshipId) {
                return builder(context, internship);
              }
            }
            return const AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Student not found',
              message:
                  'This placement isn’t assigned to you, or it was '
                  'reassigned to another lecturer.',
            );
          },
        );
  }
}
