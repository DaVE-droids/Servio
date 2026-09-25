import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/journey_track.dart';
import '../../../../core/widgets/placement_status_chip.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../supervision/presentation/providers/supervision_providers.dart';
import '../providers/assigned_students_provider.dart';

/// The lecturer's students: who they are, where they're placed, and — at a
/// glance — who still needs a supervision visit.
class LecturerAssignedStudentsScreen extends ConsumerStatefulWidget {
  /// Creates the lecturer assigned-students screen.
  const LecturerAssignedStudentsScreen({super.key});

  @override
  ConsumerState<LecturerAssignedStudentsScreen> createState() =>
      _LecturerAssignedStudentsScreenState();
}

class _LecturerAssignedStudentsScreenState
    extends ConsumerState<LecturerAssignedStudentsScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final assignedStudentsValue = ref.watch(assignedStudentsProvider);
    final lastVisits =
        ref.watch(lastVisitByInternshipProvider).value ?? const {};

    return assignedStudentsValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Your students couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.invalidate(assignedStudentsProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            icon: Icons.groups_outlined,
            title: 'No students assigned yet',
            message:
                'When a coordinator assigns a placement to you, the student '
                'will appear here.',
          );
        }

        final matches = internships.where((internship) {
          if (_query.isEmpty) {
            return true;
          }
          return [
            internship.studentName,
            internship.studentMatricNumber,
            internship.companyName,
            internship.state,
          ].join(' ').toLowerCase().contains(_query);
        }).toList();
        final notVisited = internships
            .where(
              (internship) => !lastVisits.containsKey(internship.internshipId),
            )
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(assignedStudentsProvider)
              ..invalidate(lecturerReportsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name, matric number, or company',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${Formatters.count(internships.length, 'student')}'
                '${notVisited == 0 ? ' · all visited' : ' · $notVisited not visited yet'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (matches.isEmpty)
                const AppEmptyState(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Try a different name, matric number, or company.',
                ),
              for (var i = 0; i < matches.length; i++) ...[
                FadeSlideIn(
                  index: i,
                  child: _StudentCard(
                    internship: matches[i],
                    lastVisit: lastVisits[matches[i].internshipId],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({required this.internship, required this.lastVisit});

  final InternshipModel internship;
  final DateTime? lastVisit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final name = internship.studentName.isNotEmpty
        ? internship.studentName
        : internship.studentMatricNumber;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push(
        AppRoutes.lecturerStudentDetail(internship.internshipId),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(name: name, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (internship.studentMatricNumber.isNotEmpty)
                          internship.studentMatricNumber,
                        internship.companyName,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Directions to ${internship.companyName}',
                onPressed: () => ref
                    .read(mapsServiceProvider)
                    .launchNavigation(
                      latitude: internship.companyLatitude,
                      longitude: internship.companyLongitude,
                    ),
                icon: const Icon(Icons.near_me_outlined, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    PlacementStatusChip(status: internship.status),
                    lastVisit == null
                        ? const AppStatusChip(
                            label: 'Not visited',
                            tone: AppTone.warning,
                            icon: Icons.person_pin_circle_outlined,
                          )
                        : AppStatusChip(
                            label: 'Visited ${Formatters.relative(lastVisit!)}',
                            tone: AppTone.ink,
                            icon: Icons.check_rounded,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 84,
                child: JourneyTrack.compact(status: internship.status),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
