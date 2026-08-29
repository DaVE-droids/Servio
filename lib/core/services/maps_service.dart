import 'package:geocoding/geocoding.dart' as geocoding;

import '../errors/app_failure.dart';
import '../result/result.dart';

/// A resolved latitude/longitude pair for a geocoded address.
class GeocodedLocation {
  /// Creates a geocoded location.
  const GeocodedLocation({required this.latitude, required this.longitude});

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;
}

/// Address search and navigation integration.
///
/// Geocoding is implemented with the free, on-device `geocoding` package
/// (iOS CLGeocoder / Android Geocoder) rather than Google's paid Geocoding
/// API, so it needs no API key and no Firebase billing account. See
/// docs/GEOCODING.md for how this works and how to switch to Google's API
/// later if needed.
class MapsService {
  /// Creates a maps service.
  MapsService({geocoding.Geocoding? geocoder})
    : _geocoder = geocoder ?? geocoding.Geocoding();

  final geocoding.Geocoding _geocoder;

  /// Resolves a free-text address into coordinates.
  Future<Result<GeocodedLocation>> geocodeAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        AppFailure(
          message: 'Company address is required to resolve its location.',
          type: FailureType.validation,
        ),
      );
    }

    try {
      final matches = await _geocoder.locationFromAddress(trimmed);
      if (matches.isEmpty) {
        return const Failure(
          AppFailure(
            message:
                'We could not find that company address. Please check it and try again.',
            type: FailureType.validation,
          ),
        );
      }

      final match = matches.first;
      return Success(
        GeocodedLocation(latitude: match.latitude, longitude: match.longitude),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message:
              'We could not find that company address. Please check it and try again.',
          type: FailureType.validation,
          technicalDetails: error,
        ),
      );
    }
  }
}
