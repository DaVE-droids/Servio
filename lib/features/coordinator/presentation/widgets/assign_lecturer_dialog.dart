import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Dialog that lets a coordinator pick a lecturer to assign to a placement.
///
/// Returns the selected [UserModel] via [Navigator.pop] (its name is needed
/// alongside the UID — the placement gets assigned to it directly), or
/// `null` if cancelled.
class AssignLecturerDialog extends ConsumerStatefulWidget {
  /// Creates the assign lecturer dialog.
  const AssignLecturerDialog({required this.companyName, super.key});

  /// Company name shown in the dialog title for context.
  final String companyName;

  @override
  ConsumerState<AssignLecturerDialog> createState() =>
      _AssignLecturerDialogState();
}

class _AssignLecturerDialogState extends ConsumerState<AssignLecturerDialog> {
  UserModel? _selectedLecturer;

  @override
  Widget build(BuildContext context) {
    final lecturersAsync = ref.watch(lecturersProvider);

    return AlertDialog(
      title: Text('Assign Lecturer — ${widget.companyName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: lecturersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppLoading(),
          ),
          error: (error, stackTrace) => const Text(
            'Unable to load lecturers. Please try again.',
          ),
          data: (lecturers) {
            if (lecturers.isEmpty) {
              return const Text('No lecturers are available to assign yet.');
            }
            return DropdownButtonFormField<UserModel>(
              initialValue: _selectedLecturer,
              decoration: const InputDecoration(labelText: 'Lecturer'),
              items: [
                for (final lecturer in lecturers)
                  DropdownMenuItem(
                    value: lecturer,
                    child: Text('${lecturer.firstName} ${lecturer.lastName}'),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedLecturer = value),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedLecturer == null
              ? null
              : () => Navigator.of(context).pop(_selectedLecturer),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
