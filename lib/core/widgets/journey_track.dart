import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../enums/internship_status.dart';

/// The five stops every placement passes through. This track is Servio's
/// signature element: wherever a placement appears, it shows how far along
/// the journey it is (see docs/DESIGN.md).
enum JourneyStop {
  /// Student submitted the placement.
  submitted('Submitted'),

  /// Coordinator approved it.
  approved('Approved'),

  /// A lecturer was assigned.
  assigned('Lecturer'),

  /// The internship started.
  active('Active'),

  /// The internship finished.
  completed('Completed');

  const JourneyStop(this.label);

  /// Short label under the stop.
  final String label;

  /// How many stops a status has reached (0-5), or null for a rejected
  /// placement, which left the journey at the first stop.
  static int? reachedFor(InternshipStatus? status) {
    return switch (status) {
      null || InternshipStatus.draft => 0,
      InternshipStatus.pendingReview => 1,
      InternshipStatus.approved => 2,
      InternshipStatus.assigned => 3,
      InternshipStatus.active => 4,
      InternshipStatus.completed || InternshipStatus.archived => 5,
      InternshipStatus.rejected => null,
    };
  }
}

/// Draws the placement journey for [status].
///
/// Stops already passed are solid ink with a tick; the stop the placement
/// is waiting at is a sky ring; stops ahead are hollow. A rejected
/// placement shows its first stop crossed out.
class JourneyTrack extends StatelessWidget {
  /// Creates the full track, with labels under each stop.
  const JourneyTrack({required this.status, super.key}) : compact = false;

  /// Creates a compact track for list rows: stops only, no labels.
  const JourneyTrack.compact({required this.status, super.key})
    : compact = true;

  /// The placement's status; null means no placement yet.
  final InternshipStatus? status;

  /// Whether to draw the small, label-less version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reached = JourneyStop.reachedFor(status);
    final count = JourneyStop.values.length;
    final states = [for (var i = 0; i < count; i++) _stateFor(i, reached)];
    final dot = compact ? 10.0 : 26.0;

    return Semantics(
      label: _describe(reached),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final step = (width - dot) / (count - 1);
          double centerOf(int i) => dot / 2 + step * i;
          // Five labels need room; on a narrow phone they would overlap, so
          // the track keeps its dots and names only where it is now.
          final showLabels = !compact && width >= 420;

          return SizedBox(
            height: compact ? dot : dot + 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 1; i < count; i++)
                  Positioned(
                    left: centerOf(i - 1) + dot / 2 + 3,
                    width: step - dot - 6,
                    top: dot / 2 - 1,
                    height: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            states[i] == _StopState.ahead ||
                                states[i - 1] == _StopState.rejected
                            ? AppColors.line
                            : AppColors.ink,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: centerOf(i) - dot / 2,
                    top: 0,
                    child: _Dot(state: states[i], size: dot),
                  ),
                if (showLabels)
                  for (var i = 0; i < count; i++)
                    Positioned(
                      // First and last labels hug the edges so they never
                      // overflow the track.
                      left: i == 0
                          ? 0
                          : i == count - 1
                          ? null
                          : centerOf(i) - 40,
                      right: i == count - 1 ? 0 : null,
                      width: i == 0 || i == count - 1 ? null : 80,
                      top: dot + 8,
                      child: Text(
                        JourneyStop.values[i].label,
                        textAlign: i == 0
                            ? TextAlign.left
                            : i == count - 1
                            ? TextAlign.right
                            : TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: states[i] == _StopState.current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: states[i] == _StopState.ahead
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                if (!compact && !showLabels)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: dot + 8,
                    child: Text(
                      _stageLabel(reached),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The one-line version of the track's state, for narrow screens.
  static String _stageLabel(int? reached) {
    if (reached == null) {
      return 'Rejected';
    }
    if (reached == 0) {
      return 'Not submitted yet';
    }
    final stop = JourneyStop.values[reached - 1];
    return reached == JourneyStop.values.length
        ? stop.label
        : '${stop.label} · step $reached of ${JourneyStop.values.length}';
  }

  /// A stop is done once passed, current while the placement waits there,
  /// and ahead otherwise. A completed placement has no current stop.
  static _StopState _stateFor(int index, int? reached) {
    if (reached == null) {
      return index == 0 ? _StopState.rejected : _StopState.ahead;
    }
    if (reached == 0) {
      return index == 0 ? _StopState.current : _StopState.ahead;
    }
    if (index < reached - 1 || reached == JourneyStop.values.length) {
      return index < reached ? _StopState.done : _StopState.ahead;
    }
    return index == reached - 1 ? _StopState.current : _StopState.ahead;
  }

  String _describe(int? reached) {
    if (reached == null) {
      return 'Placement rejected';
    }
    if (reached == 0) {
      return 'No placement submitted yet';
    }
    return 'Placement journey: ${JourneyStop.values[reached - 1].label}, '
        'stop $reached of 5';
  }
}

enum _StopState { done, current, ahead, rejected }

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.size});

  final _StopState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final small = size < 16;
    final (fill, border, iconColor) = switch (state) {
      _StopState.done => (AppColors.ink, AppColors.ink, Colors.white),
      _StopState.current => (AppColors.sky, AppColors.skyStrong, AppColors.ink),
      _StopState.ahead => (AppColors.surface, AppColors.lineStrong, null),
      _StopState.rejected => (
        AppColors.errorSoft,
        AppColors.error,
        AppColors.error,
      ),
    };
    final icon = switch (state) {
      _StopState.done => Icons.check_rounded,
      _StopState.rejected => Icons.close_rounded,
      _ => null,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: small ? 1.5 : 2),
      ),
      child: icon == null || small
          ? null
          : Icon(icon, size: size * 0.6, color: iconColor),
    );
  }
}
