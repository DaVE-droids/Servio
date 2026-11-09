import '../../../core/services/location_service.dart';

/// What the student can do about a missing location reading.
enum LocationNoticeAction {
  /// Nothing to open — trying again is the only step.
  none,

  /// Open the system location setting.
  openLocationSettings,

  /// Open this app's settings page.
  openAppSettings,
}

/// The words shown to a student when their location could not be read.
///
/// Kept here, away from widgets, so the wording for each case is one pure
/// mapping that can be read in one place and tested. Every message says
/// what went wrong and what to do about it; none of them accuses anyone of
/// anything, because the usual cause is a phone setting.
class LocationNotice {
  /// Creates a notice.
  const LocationNotice({
    required this.title,
    required this.message,
    required this.action,
    this.actionLabel,
  });

  /// Builds the notice for a reason a reading was unavailable.
  factory LocationNotice.of(LocationUnavailable reason) {
    return switch (reason) {
      LocationUnavailable.locationOff => const LocationNotice(
        title: 'Location is switched off',
        message:
            'Turn on location so your check-in can be confirmed as being at '
            'work.',
        action: LocationNoticeAction.openLocationSettings,
        actionLabel: 'Turn on location',
      ),
      LocationUnavailable.permissionDenied => const LocationNotice(
        title: 'Servio needs your location',
        message:
            'Your check-in can only be confirmed if Servio can see where you '
            'are. Check in again to be asked once more.',
        action: LocationNoticeAction.none,
      ),
      LocationUnavailable.permissionBlocked => const LocationNotice(
        title: 'Location access is blocked',
        message:
            'Your phone will not ask again, so this has to be changed in '
            'settings before a check-in can be confirmed.',
        action: LocationNoticeAction.openAppSettings,
        actionLabel: 'Open settings',
      ),
      LocationUnavailable.noFix => const LocationNotice(
        title: 'Couldn’t find your location',
        message:
            'Your phone didn’t return a position. This often happens deep '
            'inside a building — try again near a window or outside.',
        action: LocationNoticeAction.none,
      ),
    };
  }

  /// Short heading.
  final String title;

  /// The explanation and the way out of it.
  final String message;

  /// The settings page this notice can open, if any.
  final LocationNoticeAction action;

  /// Label for the action button, or null when there is no action.
  final String? actionLabel;
}
