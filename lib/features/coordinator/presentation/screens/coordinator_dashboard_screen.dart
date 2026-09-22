import 'package:flutter/material.dart';

import '../widgets/needs_lecturer_tab.dart';
import '../widgets/pending_review_tab.dart';
import '../widgets/ready_to_start_tab.dart';

/// Coordinator "Placements" section: pending placements awaiting review,
/// approved placements awaiting a lecturer, and assigned placements
/// awaiting activation.
///
/// Rendered inside the coordinator app shell, which supplies the app bar
/// and navigation — so the tabs live in the body rather than the app bar.
class CoordinatorDashboardScreen extends StatelessWidget {
  /// Creates the coordinator dashboard screen.
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Pending Review'),
              Tab(text: 'Needs Lecturer'),
              Tab(text: 'Ready to Start'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [PendingReviewTab(), NeedsLecturerTab(), ReadyToStartTab()],
            ),
          ),
        ],
      ),
    );
  }
}
