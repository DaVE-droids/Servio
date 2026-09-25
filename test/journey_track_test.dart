import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/enums/internship_status.dart';
import 'package:servio/core/widgets/journey_track.dart';

/// The journey track is how every role reads a placement's progress, so the
/// mapping from status to stop is worth pinning down.
void main() {
  group('JourneyStop.reachedFor', () {
    test('counts the stops each status has reached', () {
      expect(JourneyStop.reachedFor(null), 0);
      expect(JourneyStop.reachedFor(InternshipStatus.draft), 0);
      expect(JourneyStop.reachedFor(InternshipStatus.pendingReview), 1);
      expect(JourneyStop.reachedFor(InternshipStatus.approved), 2);
      expect(JourneyStop.reachedFor(InternshipStatus.assigned), 3);
      expect(JourneyStop.reachedFor(InternshipStatus.active), 4);
      expect(JourneyStop.reachedFor(InternshipStatus.completed), 5);
    });

    test('treats an archived placement as finished', () {
      expect(
        JourneyStop.reachedFor(InternshipStatus.archived),
        JourneyStop.values.length,
      );
    });

    test('marks a rejected placement as off the journey', () {
      // null means "left the journey", which the track draws as a crossed
      // out first stop rather than progress.
      expect(JourneyStop.reachedFor(InternshipStatus.rejected), isNull);
    });

    test('has a label for every stop', () {
      expect(JourneyStop.values.map((stop) => stop.label), [
        'Submitted',
        'Approved',
        'Lecturer',
        'Active',
        'Completed',
      ]);
    });
  });
}
