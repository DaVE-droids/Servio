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
