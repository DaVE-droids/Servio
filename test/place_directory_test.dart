import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/services/place_directory.dart';

/// The placement form's country and state lists come from assets/geo/,
/// trimmed from the data the country_state_city package used to bundle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every country, sorted by name', () async {
    final countries = await PlaceDirectory.countries();

    expect(countries.length, greaterThan(200));
    expect(
      countries.map((c) => c.name).toList(),
      orderedEquals(countries.map((c) => c.name).toList()..sort()),
    );
    expect(
      countries.where((c) => c.isoCode == 'NG').single.name,
      'Nigeria',
    );
  });

  test('loads the states of a country', () async {
    // Nigeria is the default in the form, so its states matter most.
    final states = await PlaceDirectory.statesOf('NG');

    expect(states, contains('Lagos'));
    expect(states.length, greaterThan(30));
    expect(states, orderedEquals([...states]..sort()));
  });

  test('a country with no states gives an empty list, not an error', () async {
    expect(await PlaceDirectory.statesOf('VA'), isEmpty);
    expect(await PlaceDirectory.statesOf('ZZ'), isEmpty);
  });
}
