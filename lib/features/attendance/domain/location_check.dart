import '../../../app/constants/app_constants.dart';
import '../data/models/attendance_model.dart';

/// How much a check-in's recorded location supports the claim that the
/// student was at their placement.
enum LocationVerdict {
  /// The reading puts the student at the company address.
  onSite,

  /// The reading is trustworthy and puts them somewhere else.
  offSite,

  /// There is nothing usable to judge: no reading was captured, it was too
  /// imprecise to mean anything, or the device reported a faked location.
  unverified,
}

/// Why a check-in came out [LocationVerdict.unverified].
enum UnverifiedReason {
  /// No coordinates were recorded (permission refused, GPS off, or a
  /// record created before location capture existed).
  noReading,

  /// The reading's own margin of error is wider than it is useful.
  tooImprecise,

  /// Android reported the location as mocked — a spoofing app.
  mocked,
}

/// The verdict on one check-in's location, derived from what was stored.
///
/// Nothing is stored for this: the verdict is worked out from the
/// coordinates, accuracy, and distance already on the attendance document,
/// so the thresholds can be retuned later without rewriting old records.
/// Records from before location capture simply come out
/// [LocationVerdict.unverified].
class LocationCheck {
  const LocationCheck._(this.verdict, {this.reason, this.distanceMetres});

  /// What the reading supports.
  final LocationVerdict verdict;

  /// Set only when [verdict] is [LocationVerdict.unverified].
  final UnverifiedReason? reason;

  /// Metres between the reading and the company address, when measured.
  final double? distanceMetres;

  /// Judges one check-in.
  ///
  /// [radiusMetres] is how far from the company address still counts as
  /// being there. [accuracyMetres] is the reading's own margin of error and
  /// is *added* to the allowance: a phone that only knows where it is to
  /// within 80 m should not put a student outside the fence on its own.
  factory LocationCheck.of({
    required double radiusMetres,
    required double maxAccuracyMetres,
    double? distanceMetres,
    double? accuracyMetres,
    bool mocked = false,
  }) {
    if (mocked) {
      return const LocationCheck._(
        LocationVerdict.unverified,
        reason: UnverifiedReason.mocked,
      );
    }
    if (distanceMetres == null) {
      return const LocationCheck._(
        LocationVerdict.unverified,
        reason: UnverifiedReason.noReading,
      );
    }
    if (accuracyMetres != null && accuracyMetres > maxAccuracyMetres) {
      return LocationCheck._(
        LocationVerdict.unverified,
        reason: UnverifiedReason.tooImprecise,
        distanceMetres: distanceMetres,
      );
    }
    final allowance = radiusMetres + (accuracyMetres ?? 0);
    return LocationCheck._(
      distanceMetres <= allowance
          ? LocationVerdict.onSite
          : LocationVerdict.offSite,
      distanceMetres: distanceMetres,
    );
  }

  /// Short label for a badge.
  String get label {
    return switch (verdict) {
      LocationVerdict.onSite => 'At the workplace',
      LocationVerdict.offSite => 'Away from the workplace',
      LocationVerdict.unverified => 'Location not confirmed',
    };
  }

  /// A sentence explaining the verdict, for a lecturer reviewing records.
  String get explanation {
    return switch (verdict) {
      LocationVerdict.onSite =>
        'The phone was ${_rounded(distanceMetres!)} from the company '
            'address at check-in.',
      LocationVerdict.offSite =>
        'The phone was ${_rounded(distanceMetres!)} from the company '
            'address at check-in.',
      LocationVerdict.unverified => switch (reason!) {
        UnverifiedReason.noReading =>
          'No location was recorded for this check-in.',
        UnverifiedReason.tooImprecise =>
          'The phone could not pin down where it was accurately enough to '
              'judge.',
        UnverifiedReason.mocked =>
          'The device reported a faked location, which means an app was '
              'overriding its real position.',
      },
    };
  }

  static String _rounded(double metres) {
    if (metres < 1000) {
      return '${metres.round()} m';
    }
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }
}

/// Reads the location verdict off an attendance record.
extension AttendanceLocationCheck on AttendanceModel {
  /// How well this record's location supports the student's claim.
  LocationCheck get locationCheck {
    return LocationCheck.of(
      radiusMetres: AppConstants.attendanceGeofenceRadiusMetres,
      maxAccuracyMetres: AppConstants.attendanceMaxLocationAccuracyMetres,
      distanceMetres: checkInDistanceMetres,
      accuracyMetres: checkInAccuracyMetres,
      mocked: checkInLocationMocked,
    );
  }
}
