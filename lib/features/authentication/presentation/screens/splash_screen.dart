import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';

/// Shown for the moment between launch and the auth session resolving.
///
/// Matches the native launch screen (a centred mark on white), so opening
/// the app is one continuous image rather than a flash between two. The
/// router sends every path here while the session loads, then on to
/// sign-in or the right home — so this screen has no logic of its own.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 96),
            SizedBox(height: 28),
            SizedBox(
              width: 96,
              child: LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
