import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../profile/data/models/user_model.dart';
import '../../domain/coordinator_overview.dart';
import '../providers/coordinator_actions_provider.dart';
import '../providers/coordinator_overview_provider.dart';
import '../widgets/coordinator_ui.dart';

/// One lecturer in full: contact details, every student they supervise
/// with that student's progress, and account access.
///
/// Like the student detail screen, it takes only an ID from the URL so a
/// browser refresh reloads it correctly.
class CoordinatorLecturerDetailScreen extends ConsumerStatefulWidget {
  /// Creates the lecturer detail screen.
  const CoordinatorLecturerDetailScreen({required this.lecturerId, super.key});

  /// The lecturer's UID.
  final String lecturerId;

  @override
  ConsumerState<CoordinatorLecturerDetailScreen> createState() =>
      _CoordinatorLecturerDetailScreenState();
}

class _CoordinatorLecturerDetailScreenState
    extends ConsumerState<CoordinatorLecturerDetailScreen> {
  var _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final overviewValue = ref.watch(coordinatorOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lecturer')),
      body: overviewValue.when(
        loading: () => const AppLoading(message: 'Loading lecturer...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load this lecturer. Please try again.',
          onRetry: () => ref.invalidate(coordinatorOverviewProvider),
        ),
        data: (overview) {
          final matches = overview.lecturers.where(
            (lecturer) => lecturer.uid == widget.lecturerId,
          );
          if (matches.isEmpty) {
            return const AppErrorState(
              message: 'This lecturer could not be found.',
            );
          }
          return _buildBody(context, overview, matches.first);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CoordinatorOverview overview,
    UserModel lecturer,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final supervised = overview.allSupervisedBy(lecturer.uid)
      ..sort((a, b) => a.studentName.compareTo(b.studentName));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              '${lecturer.firstName} ${lecturer.lastName}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SectionHeader('Details'),
            AppCard(
              child: Column(
                children: [
                  InfoRow('Staff ID', lecturer.staffId ?? '—'),
                  InfoRow('Department', lecturer.department),
                  InfoRow('Email', lecturer.email),
                  InfoRow('Phone', lecturer.phoneNumber ?? '—'),
                  InfoRow('Account', lecturer.isActive ? 'Approved' : 'Awaiting approval'),
                ],
              ),
            ),
            SectionHeader('Students supervised (${supervised.length})'),
            if (supervised.isEmpty)
              const AppCard(child: Text('No students assigned yet.'))
            else
              for (final internship in supervised) ...[
                AppCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.push(
                      AppRoutes.coordinatorStudentDetail(internship.studentId),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  internship.studentName,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PlacementStatusChip(status: internship.status),
                            ],
                          ),
                          Text(internship.companyName, style: textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.xxs),
                          ProgressLine(
                            overview.progressFor(internship.internshipId),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: lecturer.isActive ? 'Deactivate Account' : 'Approve Account',
              variant: lecturer.isActive
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              isLoading: _isUpdating,
              onPressed: () => _toggleAccess(lecturer),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAccess(UserModel lecturer) async {
    final activate = !lecturer.isActive;
    if (!activate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AppDialog(
          title: 'Deactivate this lecturer?',
          message:
              '${lecturer.firstName} ${lecturer.lastName} will lose access to '
              'their students, logbook reviews, and visit reports until '
              'approved again. Their past records are kept.',
          confirmLabel: 'Deactivate',
          onConfirm: () => Navigator.of(dialogContext).pop(true),
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
      Success<void>() => activate ? 'Lecturer approved.' : 'Lecturer deactivated.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
