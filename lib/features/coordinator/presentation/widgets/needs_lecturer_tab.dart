import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
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
import 'pending_review_tab.dart' show formatShortDate;

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
      loading: () => const AppLoading(message: 'Loading placements...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load approved placements. Please try again.',
        onRetry: () => ref.invalidate(approvedInternshipsProvider),
      ),
      data: (internships) {
        if (internships.isEmpty) {
          return const AppEmptyState(
            title: 'No Placements Waiting',
            message:
                'Every approved placement currently has a lecturer assigned.',
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
      builder: (_) =>
          AssignLecturerDialog(companyName: internship.companyName),
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
              const AppStatusChip(
                label: 'Approved',
                type: AppStatusChipType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${internship.department} • ${internship.state}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _studentLabel(internship),
            style: textTheme.bodySmall,
          ),
          if (internship.approvedAt != null)
            Text(
              'Approved ${formatShortDate(internship.approvedAt!)}',
              style: textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Assign Lecturer',
            isLoading: isProcessing,
            onPressed: isProcessing ? null : onAssign,
          ),
        ],
      ),
    );
  }
}

/// Shows the student's name, falling back to their matric number and then
/// their raw ID for placements submitted before the name was denormalized
/// onto `internships`.
String _studentLabel(InternshipModel internship) {
  if (internship.studentName.isNotEmpty) {
    final matric = internship.studentMatricNumber;
    return matric.isEmpty
        ? internship.studentName
        : '${internship.studentName} • $matric';
  }
  if (internship.studentMatricNumber.isNotEmpty) {
    return internship.studentMatricNumber;
  }
  return 'Student ${internship.studentId}';
}
