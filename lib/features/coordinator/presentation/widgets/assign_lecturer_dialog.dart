import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../providers/coordinator_overview_provider.dart';

/// Lets a coordinator pick the lecturer who will supervise a placement.
///
/// Each lecturer shows how many students they already supervise, so the
/// load can be spread evenly. Returns the chosen [UserModel] via
/// [Navigator.pop] (its name is stored with the placement), or `null` if
/// cancelled.
class AssignLecturerDialog extends ConsumerStatefulWidget {
  /// Creates the assign lecturer dialog.
  const AssignLecturerDialog({
    required this.companyName,
    this.studentName,
    super.key,
  });

  /// Company name shown for context.
  final String companyName;

  /// Student name shown for context.
  final String? studentName;

  @override
  ConsumerState<AssignLecturerDialog> createState() =>
      _AssignLecturerDialogState();
}

class _AssignLecturerDialogState extends ConsumerState<AssignLecturerDialog> {
  UserModel? _selected;

  @override
  Widget build(BuildContext context) {
    final lecturersAsync = ref.watch(lecturersProvider);
    final overview = ref.watch(coordinatorOverviewProvider).value;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Assign a lecturer'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                if (widget.studentName != null) widget.studentName!,
                widget.companyName,
              ].join(' · '),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: lecturersAsync.when(
                loading: () => const Shimmer(
                  child: Column(
                    children: [
                      SkeletonBox(height: 56, radius: AppRadii.control),
                      SizedBox(height: AppSpacing.xs),
                      SkeletonBox(height: 56, radius: AppRadii.control),
                    ],
                  ),
                ),
                error: (error, stackTrace) =>
                    const Text('Lecturers couldn’t be loaded. Try again.'),
                data: (allLecturers) {
                  // Only approved lecturers can supervise; the security
                  // rules reject an assignment to an unapproved one anyway.
                  final lecturers = allLecturers
                      .where((lecturer) => lecturer.isActive)
                      .toList();
                  if (lecturers.isEmpty) {
                    return const Text(
                      'No approved lecturers yet. Approve lecturers in the '
                      'Lecturers section first.',
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: lecturers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final lecturer = lecturers[index];
                      final load = overview?.activeLoadFor(lecturer.uid).length;
                      return _LecturerOption(
                        lecturer: lecturer,
                        load: load,
                        isSelected: _selected?.uid == lecturer.uid,
                        onTap: () => setState(() => _selected = lecturer),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

class _LecturerOption extends StatelessWidget {
  const _LecturerOption({
    required this.lecturer,
    required this.load,
    required this.isSelected,
    required this.onTap,
  });

  final UserModel lecturer;
  final int? load;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = '${lecturer.firstName} ${lecturer.lastName}';
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.inkSoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(
            color: isSelected ? AppColors.ink : AppColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                AppAvatar(
                  name: name,
                  photoUrl: lecturer.profilePhotoUrl,
                  size: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: textTheme.titleSmall),
                      Text(lecturer.department, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                if (load != null)
                  Text(
                    Formatters.count(load!, 'student'),
                    style: textTheme.labelMedium,
                  ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSelected ? AppColors.ink : AppColors.lineStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
