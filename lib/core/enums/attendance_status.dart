/// Lifecycle states for attendance records.
enum AttendanceStatus {
  /// Student has checked in.
  checkedIn,

  /// Student has checked out.
  completed,

  /// Attendance was missed.
  missed,

  /// Attendance is incomplete.
  incomplete,
}

/// Serialization helpers for [AttendanceStatus].
extension AttendanceStatusSerialization on AttendanceStatus {
  /// Firestore value defined by the DDS.
  String get firestoreValue {
    return switch (this) {
      AttendanceStatus.checkedIn => 'checked_in',
      AttendanceStatus.completed => 'completed',
      AttendanceStatus.missed => 'missed',
      AttendanceStatus.incomplete => 'incomplete',
    };
  }

  /// Human-readable label for UI status display.
  String get label {
    return switch (this) {
      AttendanceStatus.checkedIn => 'Checked In',
      AttendanceStatus.completed => 'Completed',
      AttendanceStatus.missed => 'Missed',
      AttendanceStatus.incomplete => 'Incomplete',
    };
  }

  /// Parses a DDS Firestore value into an attendance status.
  static AttendanceStatus fromFirestore(String value) {
    return switch (value) {
      'checked_in' => AttendanceStatus.checkedIn,
      'completed' => AttendanceStatus.completed,
      'missed' => AttendanceStatus.missed,
      'incomplete' => AttendanceStatus.incomplete,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unknown attendance status',
      ),
    };
  }
}
