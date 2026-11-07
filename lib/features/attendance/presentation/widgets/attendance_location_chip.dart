import 'package:flutter/material.dart';

import '../../../../app/theme/app_tone.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/location_check.dart';

/// Shows whether a check-in's location backs up the student's claim.
///
/// Deliberately not alarming: "not confirmed" is the common case for an
/// older record or a phone with location switched off, and means only that
/// there is nothing to go on — not that anyone did anything wrong.
class AttendanceLocationChip extends StatelessWidget {
  /// Creates a location chip for one attendance record.
  const AttendanceLocationChip({required this.record, super.key});

  /// The record being described.
  final AttendanceModel record;

  @override
  Widget build(BuildContext context) {
    final check = record.locationCheck;
    final (icon, tone) = switch (check.verdict) {
      LocationVerdict.onSite => (Icons.place_outlined, AppTone.success),
      LocationVerdict.offSite => (Icons.wrong_location_outlined, AppTone.error),
      LocationVerdict.unverified => (
        Icons.location_off_outlined,
        AppTone.neutral,
      ),
    };

    return Tooltip(
      message: check.explanation,
      triggerMode: TooltipTriggerMode.tap,
      child: AppStatusChip(label: check.label, icon: icon, tone: tone),
    );
  }
}
