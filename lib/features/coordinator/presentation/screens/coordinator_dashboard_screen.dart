import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../widgets/needs_lecturer_tab.dart';
import '../widgets/pending_review_tab.dart';
import '../widgets/ready_to_start_tab.dart';

/// Coordinator dashboard: pending placements awaiting review, approved
/// placements awaiting a lecturer assignment, and assigned placements
/// awaiting activation.
class CoordinatorDashboardScreen extends ConsumerWidget {
  /// Creates the coordinator dashboard screen.
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coordinator Dashboard'),
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
              tooltip: 'Profile',
            ),
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
              Tab(text: 'Ready to Start'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [PendingReviewTab(), NeedsLecturerTab(), ReadyToStartTab()],
        ),
      ),
    );
  }
}
