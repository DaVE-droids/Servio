import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A country a placement can be in.
class GeoCountry {
  /// Creates a country.
  const GeoCountry({required this.isoCode, required this.name});

  /// ISO 3166-1 alpha-2 code, used to look up states and to scope address
  /// search.
  final String isoCode;

  /// Display name.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is GeoCountry && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}

/// Countries and their states, for the placement form's two dropdowns.
///
/// The data lives in `assets/geo/` and holds only what the form needs: a
/// country's code and name, and each country's state names. It replaces the
/// `country_state_city` package, which bundled a 24 MB list of world cities
/// that Servio never read — harmless on the web (the browser never fetches
/// it) but 24 MB added to every Android and iOS download.
///
/// To refresh the data, see `tool/generate_geo_assets.py`.
abstract final class PlaceDirectory {
  static Future<List<GeoCountry>>? _countries;
  static Future<Map<String, List<String>>>? _states;

  /// Every country, sorted by name. Parsed once and reused.
  static Future<List<GeoCountry>> countries() {
    return _countries ??= rootBundle
        .loadString('assets/geo/countries.json')
        .then(
          (raw) => [
            for (final entry in jsonDecode(raw) as List)
              GeoCountry(
                isoCode: (entry as Map)['c'] as String,
                name: entry['n'] as String,
              ),
          ],
        );
  }

  /// The states of one country, sorted by name; empty for countries that
  /// have none in the data.
  static Future<List<String>> statesOf(String isoCode) async {
    _states ??= rootBundle
        .loadString('assets/geo/states.json')
        .then(
          (raw) => (jsonDecode(raw) as Map<String, dynamic>).map(
            (code, names) => MapEntry(code, [
              for (final name in names as List) name as String,
            ]),
          ),
        );
    return (await _states!)[isoCode] ?? const [];
  }
}
