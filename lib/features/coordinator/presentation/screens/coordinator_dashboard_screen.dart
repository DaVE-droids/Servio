import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../widgets/needs_lecturer_tab.dart';
import '../widgets/pending_review_tab.dart';

/// Coordinator dashboard: pending placements awaiting review, and approved
/// placements awaiting a lecturer assignment.
class CoordinatorDashboardScreen extends ConsumerWidget {
  /// Creates the coordinator dashboard screen.
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coordinator Dashboard'),
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Review'),
              Tab(text: 'Needs Lecturer'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [PendingReviewTab(), NeedsLecturerTab()],
        ),
      ),
    );
  }
}
