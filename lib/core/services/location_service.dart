import 'package:geolocator/geolocator.dart';

/// One attempt to find out where the device is.
///
/// A failed attempt is not an error to show as a red banner: a check-in
/// still goes through without a reading, marked as unconfirmed. So this
/// carries a reading or nothing, and never throws.
class LocationReading {
  /// Creates a reading.
  const LocationReading({
    this.latitude,
    this.longitude,
    this.accuracyMetres,
    this.isMocked = false,
  });

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

  /// Whether coordinates were captured at all.
  bool get hasPosition => latitude != null && longitude != null;
}

/// Reads the device's position for attendance check-ins.
class LocationService {
  /// Creates a location service.
  const LocationService();

  /// Tries to read the current position, asking for permission if needed.
  ///
  /// Returns an empty reading rather than throwing when location is off,
  /// permission is refused, or the fix times out — a student should never
  /// be unable to check in because of their phone's GPS.
  Future<LocationReading> current({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationReading();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationReading();
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
      // browser prompt: all mean the same thing here — no reading.
      return const LocationReading();
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
