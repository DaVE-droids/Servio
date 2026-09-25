import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../internship/data/models/internship_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../providers/approved_internships_provider.dart';
import 'assign_lecturer_dialog.dart';
import 'coordinator_ui.dart';

/// Coordinator dashboard tab listing approved placements that still need a
/// lecturer assigned.
class NeedsLecturerTab extends ConsumerStatefulWidget {
  /// Creates the needs-lecturer tab.
  const NeedsLecturerTab({super.key});

  @override
  ConsumerState<NeedsLecturerTab> createState() => _NeedsLecturerTabState();
}

class _NeedsLecturerTabState extends ConsumerState<NeedsLecturerTab> {
  final _processingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final approvedInternshipsAsync = ref.watch(approvedInternshipsProvider);

    return approvedInternshipsAsync.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Placements couldn’t be loaded. Check your connection and '
            'try again.',
        onRetry: () => ref.invalidate(approvedInternshipsProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_add_alt_outlined,
            tone: AppTone.blush,
            title: 'Every approved placement has a lecturer',
            message:
                'When you approve a placement, it waits here until you assign '
                'a supervising lecturer.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(approvedInternshipsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: internships.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final internship = internships[index];
              return _NeedsLecturerCard(
                internship: internship,
                isProcessing: _processingIds.contains(internship.internshipId),
                onAssign: () => _assign(internship),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _assign(InternshipModel internship) async {
    final lecturer = await showDialog<UserModel>(
      context: context,
      builder: (_) => AssignLecturerDialog(
        companyName: internship.companyName,
        studentName: internship.studentName,
      ),
    );

    if (lecturer == null || !mounted) {
      return;
    }

    setState(() => _processingIds.add(internship.internshipId));

    final result = await ref
        .read(approvedInternshipsProvider.notifier)
        .assignLecturer(
          internship: internship,
          lecturerId: lecturer.uid,
          lecturerName: '${lecturer.firstName} ${lecturer.lastName}',
        );

    if (!mounted) {
      return;
    }
    setState(() => _processingIds.remove(internship.internshipId));

    final message = switch (result) {
      Success<void>() => 'Lecturer assigned.',
      Failure<void>(:final error) => error.message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NeedsLecturerCard extends StatelessWidget {
  const _NeedsLecturerCard({
    required this.internship,
    required this.isProcessing,
    required this.onAssign,
  });

  final InternshipModel internship;
  final bool isProcessing;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlacementCardHeader(
            internship: internship,
            chip: AppStatusChip(
              label: internship.approvedAt == null
                  ? 'Approved'
                  : 'Approved ${Formatters.relative(internship.approvedAt!)}',
              tone: AppTone.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Assign lecturer',
            icon: Icons.person_add_alt_rounded,
            isLoading: isProcessing,
            onPressed: onAssign,
          ),
        ],
      ),
    );
  }
}
