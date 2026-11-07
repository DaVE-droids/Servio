import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/attendance/domain/location_check.dart';

void main() {
  LocationCheck check({
    double? distanceMetres,
    double? accuracyMetres,
    bool mocked = false,
  }) {
    return LocationCheck.of(
      radiusMetres: 250,
      maxAccuracyMetres: 200,
      distanceMetres: distanceMetres,
      accuracyMetres: accuracyMetres,
      mocked: mocked,
    );
  }

  group('LocationCheck', () {
    test('counts a reading inside the fence as on site', () {
      expect(
        check(distanceMetres: 40, accuracyMetres: 12).verdict,
        LocationVerdict.onSite,
      );
    });

    test('counts a reading well outside the fence as off site', () {
      final result = check(distanceMetres: 8000, accuracyMetres: 15);
      expect(result.verdict, LocationVerdict.offSite);
      expect(result.explanation, contains('8.0 km'));
    });

    test('adds the margin of error to the allowance', () {
      // 300 m away is outside the 250 m fence on its own, but a phone that
      // only knows its position to within 80 m could genuinely be inside
      // it, so this student is not marked as absent.
      expect(check(distanceMetres: 300, accuracyMetres: 80).verdict,
          LocationVerdict.onSite);
      expect(check(distanceMetres: 300, accuracyMetres: 10).verdict,
          LocationVerdict.offSite);
    });

    test('refuses to judge a reading vaguer than the limit', () {
      final result = check(distanceMetres: 5000, accuracyMetres: 900);
      expect(result.verdict, LocationVerdict.unverified);
      expect(result.reason, UnverifiedReason.tooImprecise);
    });

    test('treats a faked location as unverified, however close it claims '
        'to be', () {
      final result = check(distanceMetres: 1, accuracyMetres: 5, mocked: true);
      expect(result.verdict, LocationVerdict.unverified);
      expect(result.reason, UnverifiedReason.mocked);
    });

    test('reports no reading when nothing was captured', () {
      // Every attendance record created before location capture existed
      // lands here, which is why these are never shown as off site.
      final result = check();
      expect(result.verdict, LocationVerdict.unverified);
      expect(result.reason, UnverifiedReason.noReading);
      expect(result.distanceMetres, isNull);
    });

    test('a reading with no accuracy figure is still judged', () {
      expect(check(distanceMetres: 100).verdict, LocationVerdict.onSite);
      expect(check(distanceMetres: 900).verdict, LocationVerdict.offSite);
    });
  });
}
