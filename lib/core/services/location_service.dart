import 'package:geolocator/geolocator.dart';

/// Why a position could not be read.
///
/// Each case needs a different thing from the person holding the phone, so
/// they are kept apart rather than collapsed into one "no location".
enum LocationUnavailable {
  /// The device's location setting is switched off system-wide.
  locationOff,

  /// Permission was asked for and refused this time.
  permissionDenied,

  /// Permission was refused permanently, so the system will not ask again.
  /// Only the app's settings page can change this.
  permissionBlocked,

  /// A fix was allowed but never arrived — a timeout, no signal indoors, or
  /// a platform without location support.
  noFix,
}

/// One attempt to find out where the device is.
///
/// A failed attempt is not an error to show as a red banner: a check-in
/// still goes through without a reading, marked as unconfirmed. So this
/// carries a reading or a reason there isn't one, and never throws.
class LocationReading {
  /// Creates a reading.
  const LocationReading({
    this.latitude,
    this.longitude,
    this.accuracyMetres,
    this.isMocked = false,
    this.unavailable,
  });

  /// Creates an empty reading that says why it is empty.
  const LocationReading.unusable(LocationUnavailable reason)
    : this(unavailable: reason);

  /// Latitude, or null if nothing was captured.
  final double? latitude;

  /// Longitude, or null if nothing was captured.
  final double? longitude;

  /// The reading's own margin of error in metres, as reported by the
  /// platform.
  final double? accuracyMetres;

  /// Whether the platform said this position came from a mock provider.
  /// Android only; always false on iOS and the web, which do not report it.
  final bool isMocked;

  /// Why there is no position, or null when there is one.
  final LocationUnavailable? unavailable;

  /// Whether coordinates were captured at all.
  bool get hasPosition => latitude != null && longitude != null;
}

/// Reads the device's position for attendance check-ins.
class LocationService {
  /// Creates a location service.
  const LocationService();

  /// Tries to read the current position, asking for permission if needed.
  ///
  /// Permission is requested *before* the system location setting is
  /// checked. The other order looks more logical and is wrong: a phone with
  /// location switched off would return early and the person would never
  /// see a permission prompt at all, so the feature would appear to do
  /// nothing. Asking first means the prompts arrive in the order that lets
  /// someone actually fix the problem.
  ///
  /// Returns an empty reading carrying a reason rather than throwing — a
  /// student should never be unable to check in because of their phone's
  /// GPS.
  Future<LocationReading> current({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationReading.unusable(
          LocationUnavailable.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationReading.unusable(
          LocationUnavailable.permissionBlocked,
        );
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationReading.unusable(LocationUnavailable.locationOff);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LocationReading(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
        isMocked: position.isMocked,
      );
    } catch (_) {
      // Timeouts, a plugin missing on an unsupported platform, a refused
      // browser prompt: all mean the same thing here — nothing to go on.
      return const LocationReading.unusable(LocationUnavailable.noFix);
    }
  }

  /// Opens the system location setting, for a phone with location off.
  ///
  /// Returns false where there is nothing to open, such as on the web.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Opens this app's settings page, the only place a permanently refused
  /// permission can be granted again.
  ///
  /// Returns false where there is nothing to open, such as on the web.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Metres between two coordinates.
  double distanceBetween({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }
}
