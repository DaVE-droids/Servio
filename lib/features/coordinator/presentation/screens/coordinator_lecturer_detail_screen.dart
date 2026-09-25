import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/internship_status.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/person_header.dart';
import '../../../../core/widgets/responsive_columns.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// One lecturer in full: contact details, workload, every student they
/// supervise with that student's progress, and account access.
///
/// Takes only an ID from the URL so a browser refresh reloads it correctly.
class CoordinatorLecturerDetailScreen extends ConsumerWidget {
  /// Creates the lecturer detail screen.
  const CoordinatorLecturerDetailScreen({required this.lecturerId, super.key});

  /// The lecturer's UID.
  final String lecturerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(coordinatorOverviewProvider)
        .when(
          loading: () => const AppLoading(layout: AppLoadingLayout.detail),
          error: (error, stackTrace) => AppErrorState(
            message:
                'This lecturer couldn’t be loaded. Check your connection '
                'and try again.',
            onRetry: () => ref.invalidate(coordinatorOverviewProvider),
          ),
          data: (overview) {
            final lecturer = overview.lecturers
                .where((lecturer) => lecturer.uid == lecturerId)
                .firstOrNull;
            if (lecturer == null) {
              return const AppEmptyState(
                icon: Icons.person_off_outlined,
                title: 'Lecturer not found',
                message: 'This account may have been removed.',
              );
            }
            return _Body(overview: overview, lecturer: lecturer);
          },
        );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.overview, required this.lecturer});

  final CoordinatorOverview overview;
  final UserModel lecturer;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  var _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final lecturer = widget.lecturer;
    final name = '${lecturer.firstName} ${lecturer.lastName}';
    final supervised = overview.allSupervisedBy(lecturer.uid)
      ..sort((a, b) => a.studentName.compareTo(b.studentName));
    final current = overview.activeLoadFor(lecturer.uid);
    final visits = supervised.fold<int>(
      0,
      (sum, internship) =>
          sum + overview.progressFor(internship.internshipId).visits,
    );
    final unvisited = current
        .where(
          (internship) =>
              internship.status == InternshipStatus.active &&
              overview.progressFor(internship.internshipId).visits == 0,
        )
        .length;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(coordinatorOverviewProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ResponsiveColumns(
            primary: [
              PersonHeader(
                name: name,
                photoUrl: lecturer.profilePhotoUrl,
                tags: [lecturer.staffId ?? '', lecturer.department],
                status: AppStatusChip(
                  label: lecturer.isActive ? 'Approved' : 'Awaiting approval',
                  type: lecturer.isActive
                      ? AppStatusChipType.success
                      : AppStatusChipType.warning,
                ),
              ),
              SectionCard(
                title: 'Contact',
                child: InfoPanel(
                  rows: [
                    InfoRow('Email', lecturer.email, icon: Icons.mail_outline),
                    InfoRow(
                      'Phone',
                      lecturer.phoneNumber ?? '—',
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Account access',
                subtitle: lecturer.isActive
                    ? 'Deactivating removes access to their students until '
                          'approved again. Past records are kept.'
                    : 'Approving lets this lecturer be assigned students.',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: lecturer.isActive
                        ? 'Deactivate account'
                        : 'Approve account',
                    variant: lecturer.isActive
                        ? AppButtonVariant.secondary
                        : AppButtonVariant.primary,
                    expand: false,
                    isLoading: _isUpdating,
                    onPressed: () => _toggleAccess(lecturer),
                  ),
                ),
              ),
            ],
            secondary: [
              StatGrid(
                maxColumns: 3,
                children: [
                  StatTile(
                    value: '${current.length}',
                    label: 'Current students',
                    icon: Icons.groups_outlined,
                    tone: AppTone.sky,
                    highlighted: true,
                  ),
                  StatTile(
                    value: '$visits',
                    label: 'Visits logged',
                    icon: Icons.person_pin_circle_outlined,
                  ),
                  StatTile(
                    value: '$unvisited',
                    label: 'Active, not visited',
                    icon: Icons.warning_amber_rounded,
                    tone: unvisited > 0 ? AppTone.warning : AppTone.success,
                  ),
                ],
              ),
              SectionCard(
                title: 'Students supervised',
                trailing: Text(
                  '${supervised.length} total',
                  style: textTheme.bodySmall,
                ),
                child: supervised.isEmpty
                    ? const AppEmptyState(
                        compact: true,
                        icon: Icons.groups_outlined,
                        title: 'No students yet',
                        message:
                            'Assign placements to this lecturer from Placements.',
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < supervised.length; i++) ...[
                            if (i > 0) const Divider(),
                            InkWell(
                              onTap: () => context.push(
                                AppRoutes.coordinatorStudentDetail(
                                  supervised[i].studentId,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    AppAvatar(
                                      name: supervised[i].studentName,
                                      size: 38,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            supervised[i].studentName,
                                            style: textTheme.titleSmall,
                                          ),
                                          Text(
                                            supervised[i].companyName,
                                            style: textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          ProgressLine(
                                            overview.progressFor(
                                              supervised[i].internshipId,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PlacementStatusChip(
                                      status: supervised[i].status,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _toggleAccess(UserModel lecturer) async {
    final activate = !lecturer.isActive;
    if (!activate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AppDialog(
          icon: Icons.person_off_outlined,
          isDestructive: true,
          title: 'Deactivate this lecturer?',
          message:
              '${lecturer.firstName} ${lecturer.lastName} will lose access to '
              'their students, logbook reviews, and visit reports until '
              'approved again. Their past records are kept.',
          confirmLabel: 'Deactivate',
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _isUpdating = true);
    final result = await ref
        .read(coordinatorActionsProvider)
        .setLecturerActive(lecturer, isActive: activate);
    if (!mounted) {
      return;
    }
    setState(() => _isUpdating = false);
    final message = switch (result) {
      Success<void>() =>
        activate ? 'Lecturer approved and notified.' : 'Lecturer deactivated.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
