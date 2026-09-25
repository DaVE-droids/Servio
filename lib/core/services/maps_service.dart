import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

/// A single address suggestion returned while searching, carrying its own
/// resolved coordinates so no separate geocoding step is needed once one is
/// picked.
class AddressSuggestion {
  /// Creates an address suggestion.
  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  /// Human-readable address, shown in the suggestion list.
  final String displayName;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;
}

/// LocationIQ access token, supplied at build/run time so it's never
/// hardcoded or committed. Pass with:
/// `flutter run --dart-define=LOCATIONIQ_ACCESS_TOKEN=your_token`
/// See docs/LOCATION_SERVICES.md.
const _locationIqAccessToken = String.fromEnvironment(
  'LOCATIONIQ_ACCESS_TOKEN',
);

/// Address search and navigation integration.
///
/// Address search (autocomplete) is implemented with LocationIQ (built on
/// OpenStreetMap data) since it's free and explicitly permits autocomplete
/// usage, unlike the raw OpenStreetMap Nominatim service. Forward geocoding
/// a single typed address (no suggestion list) still falls back to the free,
/// on-device `geocoding` package. Navigation opens the device's installed
/// maps app via a plain URL — no API key needed for that at all. See
/// docs/LOCATION_SERVICES.md and docs/GEOCODING.md.
class MapsService {
  /// Creates a maps service.
  MapsService({geocoding.Geocoding? geocoder, http.Client? httpClient})
    : _injectedGeocoder = geocoder,
      _httpClient = httpClient ?? http.Client();

  final geocoding.Geocoding? _injectedGeocoder;
  final http.Client _httpClient;

  /// The on-device geocoder, created only on first use.
  ///
  /// Created lazily — and never in a browser — because the `geocoding`
  /// plugin has no web implementation: merely constructing it throws on
  /// web. It used to be built in this constructor, which crashed the whole
  /// service in the web app and took address search down with it, even
  /// though address search doesn't use the geocoder at all.
  late final geocoding.Geocoding _geocoder =
      _injectedGeocoder ?? geocoding.Geocoding();

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

    if (kIsWeb) {
      // No on-device geocoder exists in a browser. Callers on web should use
      // [searchAddress], whose suggestions already carry coordinates.
      return const Failure(
        AppFailure(
          message: 'Please pick the company address from the suggestions.',
          type: FailureType.validation,
          code: 'geocoding-unsupported-on-web',
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

  /// Searches for address suggestions as the user types, optionally scoped
  /// to a country (ISO 3166-1 alpha-2 code, e.g. `NG`). Each suggestion
  /// already carries its own coordinates.
  Future<Result<List<AddressSuggestion>>> searchAddress(
    String query, {
    String? countryCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return const Success([]);
    }
    if (_locationIqAccessToken.isEmpty) {
      return const Failure(
        AppFailure(
          message: 'Address search is not configured. Please contact support.',
          type: FailureType.unknown,
          code: 'locationiq-key-missing',
        ),
      );
    }

    try {
      final uri = Uri.https('api.locationiq.com', '/v1/autocomplete', {
        'key': _locationIqAccessToken,
        'q': trimmed,
        'format': 'json',
        'limit': '6',
        if (countryCode != null && countryCode.isNotEmpty)
          'countrycodes': countryCode,
      });
      final response = await _httpClient.get(uri);

      if (response.statusCode == 404) {
        // LocationIQ returns 404 for "no results found" rather than an
        // empty array, unlike most REST APIs.
        return const Success([]);
      }
      if (response.statusCode != 200) {
        return Failure(
          AppFailure(
            message: 'Address search is unavailable right now.',
            type: FailureType.network,
            code: 'locationiq-${response.statusCode}',
            technicalDetails: response.body,
          ),
        );
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final suggestions = body
          .cast<Map<String, dynamic>>()
          .map(
            (entry) => AddressSuggestion(
              displayName: entry['display_name'] as String,
              latitude: double.parse(entry['lat'] as String),
              longitude: double.parse(entry['lon'] as String),
            ),
          )
          .toList();
      return Success(suggestions);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Address search is unavailable right now.',
          type: FailureType.network,
          technicalDetails: error,
        ),
      );
    }
  }

  /// Opens the device's installed maps app with directions to the given
  /// coordinates. Uses free, public maps deep-link URLs — no API key, no
  /// paid Maps SDK/API involved. Picks Apple Maps' own URL on iOS (always
  /// present on every iPhone/Simulator, so its own in-app "Start" button
  /// always has a real app to hand off to) and Google's public "Maps URLs"
  /// format everywhere else (Android, web, desktop), since Google Maps is
  /// near-universal there.
  Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
  }) {
    final uri = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
          );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
