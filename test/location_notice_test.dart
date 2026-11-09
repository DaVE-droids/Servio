import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/services/location_service.dart';
import 'package:servio/features/attendance/domain/location_notice.dart';

void main() {
  group('LocationNotice', () {
    test('covers every reason a reading can be unavailable', () {
      for (final reason in LocationUnavailable.values) {
        final notice = LocationNotice.of(reason);
        expect(notice.title, isNotEmpty, reason: '$reason has no title');
        expect(notice.message, isNotEmpty, reason: '$reason has no message');
      }
    });

    test('offers the system location setting when location is off', () {
      final notice = LocationNotice.of(LocationUnavailable.locationOff);
      expect(notice.action, LocationNoticeAction.openLocationSettings);
      expect(notice.actionLabel, isNotNull);
    });

    test('sends a blocked permission to the app settings page', () {
      // The system will not prompt again, so the only way back is settings.
      final notice = LocationNotice.of(LocationUnavailable.permissionBlocked);
      expect(notice.action, LocationNoticeAction.openAppSettings);
      expect(notice.actionLabel, isNotNull);
    });

    test('offers no settings page where trying again is the fix', () {
      for (final reason in [
        LocationUnavailable.permissionDenied,
        LocationUnavailable.noFix,
      ]) {
        final notice = LocationNotice.of(reason);
        expect(notice.action, LocationNoticeAction.none);
        expect(notice.actionLabel, isNull);
      }
    });

    test('every notice with an action has a label for its button', () {
      for (final reason in LocationUnavailable.values) {
        final notice = LocationNotice.of(reason);
        expect(
          notice.actionLabel == null,
          notice.action == LocationNoticeAction.none,
          reason: '$reason has an action and label that disagree',
        );
      }
    });
  });

  group('LocationReading', () {
    test('an unusable reading has no position but says why', () {
      const reading = LocationReading.unusable(LocationUnavailable.locationOff);
      expect(reading.hasPosition, isFalse);
      expect(reading.unavailable, LocationUnavailable.locationOff);
    });

    test('a reading with coordinates has no reason attached', () {
      const reading = LocationReading(
        latitude: 6.5,
        longitude: 3.3,
        accuracyMetres: 12,
      );
      expect(reading.hasPosition, isTrue);
      expect(reading.unavailable, isNull);
    });

    test('a half-filled reading does not count as a position', () {
      const reading = LocationReading(latitude: 6.5);
      expect(reading.hasPosition, isFalse);
    });
  });
}
