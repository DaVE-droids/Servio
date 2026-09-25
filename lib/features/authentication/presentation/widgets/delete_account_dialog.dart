import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/authentication_providers.dart';

/// Confirms, with the user's password, that they want their account gone.
///
/// Spells out what is deleted and what the institution keeps, because
/// placement records outlive the account (see the privacy policy).
class DeleteAccountDialog extends ConsumerStatefulWidget {
  /// Creates the delete account dialog.
  const DeleteAccountDialog({required this.role, super.key});

  /// The user's role, which changes what's worth warning about.
  final UserRole role;

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  String? _error;
  var _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kept = switch (widget.role) {
      UserRole.student =>
        'Your placement, attendance, logbook, and visit records stay with '
            'your institution as academic records.',
      UserRole.lecturer =>
        'Visit reports and logbook reviews you made stay with the '
            'institution. Your coordinator will need to reassign your '
            'students.',
      UserRole.coordinator =>
        'Decisions you recorded stay in the audit history.',
    };

    return AlertDialog(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTone.error.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      title: const Text('Delete your account?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently deletes your sign-in, your profile, and your '
              'photo. It can’t be undone.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(kept, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Enter your password to confirm',
              controller: _passwordController,
              obscureText: true,
              enabled: !_isDeleting,
              autofillHints: const [AutofillHints.password],
              errorText: _error,
              onSubmitted: (_) => _delete(),
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
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Keep my account'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.6),
          ),
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete account'),
        ),
      ],
    );
  }

  Future<void> _delete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _error = null;
      _isDeleting = true;
    });
    // Called directly rather than through the auth controller, so a wrong
    // password shows once, here, instead of also as an app-wide message.
    final result = await ref
        .read(authenticationRepositoryProvider)
        .deleteAccount(password);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<void>():
        // The session has ended; the router is already heading to sign-in.
        Navigator.of(context).pop();
      case Failure<void>(:final error):
        setState(() {
          _isDeleting = false;
          _error = error.message;
        });
    }
  }
}
