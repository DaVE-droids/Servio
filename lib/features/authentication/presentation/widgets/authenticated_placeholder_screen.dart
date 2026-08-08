import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/authentication_providers.dart';

/// Placeholder screen for protected routes with a working logout action.
class AuthenticatedPlaceholderScreen extends ConsumerWidget {
  /// Creates an authenticated placeholder screen.
  const AuthenticatedPlaceholderScreen({
    required this.title,
    required this.description,
    super.key,
  });

  /// Screen title.
  final String title;

  /// Placeholder description.
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);

    ref.listen(authenticationControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: authState.isLoading
                ? null
                : () => ref
                      .read(authenticationControllerProvider.notifier)
                      .logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppEmptyState(title: title, message: description),
      ),
      bottomNavigationBar: const SizedBox(height: AppSpacing.sm),
    );
  }
}
