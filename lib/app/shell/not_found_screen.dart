import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/brand_mark.dart';
import '../constants/app_routes.dart';
import '../theme/app_spacing.dart';

/// Shown for a link that doesn't match any page, such as a mistyped URL.
class NotFoundScreen extends StatelessWidget {
  /// Creates the not-found screen.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLockup(markSize: 30),
              ),
            ),
            Expanded(
              child: AppEmptyState(
                icon: Icons.explore_off_outlined,
                title: 'This page doesn’t exist',
                message:
                    'The link may be mistyped, or the page may have moved.',
                actionLabel: 'Go to my home page',
                // The splash route sends a signed-in user to their own
                // dashboard and anyone else to sign-in.
                onActionPressed: () => context.go(AppRoutes.splash),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
