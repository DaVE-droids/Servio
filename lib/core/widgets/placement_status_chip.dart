import 'package:flutter/material.dart';

import '../enums/internship_status.dart';
import 'app_status_chip.dart';

/// Coloured chip for a student's placement status; `null` means the student
/// hasn't submitted a placement at all.
class PlacementStatusChip extends StatelessWidget {
  /// Creates a placement status chip.
  const PlacementStatusChip({required this.status, super.key});

  /// The placement status, or null for "no placement".
  final InternshipStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, type) = placementStatusLabel(status);
    return AppStatusChip(label: label, type: type);
  }
}

/// Human label and chip colour for a placement status.
(String, AppStatusChipType) placementStatusLabel(InternshipStatus? status) {
  return switch (status) {
    null => ('No placement', AppStatusChipType.neutral),
    InternshipStatus.draft => ('Draft', AppStatusChipType.neutral),
    InternshipStatus.pendingReview => (
      'Pending review',
      AppStatusChipType.warning,
    ),
    InternshipStatus.approved => ('Needs lecturer', AppStatusChipType.warning),
    InternshipStatus.rejected => ('Rejected', AppStatusChipType.error),
    InternshipStatus.assigned => ('Ready to start', AppStatusChipType.info),
    InternshipStatus.active => ('Active', AppStatusChipType.success),
    InternshipStatus.completed => ('Completed', AppStatusChipType.success),
    InternshipStatus.archived => ('Archived', AppStatusChipType.neutral),
  };
}
