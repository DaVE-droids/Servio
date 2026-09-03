/// Named route paths used by GoRouter throughout Servio.
abstract final class AppRoutes {
  /// Splash route.
  static const splash = '/';

  /// Login placeholder route.
  static const login = '/login';

  /// Registration route.
  static const register = '/register';

  /// Forgot password route.
  static const forgotPassword = '/forgot-password';

  /// Email verification placeholder route.
  static const verification = '/verification';

  /// Student dashboard route.
  static const studentDashboard = '/student/dashboard';

  /// Lecturer dashboard route.
  static const lecturerDashboard = '/lecturer/dashboard';

  /// Coordinator dashboard route.
  static const coordinatorDashboard = '/coordinator/dashboard';

  /// Internship route.
  static const internship = '/internship';

  /// Attendance route.
  static const attendance = '/attendance';

  /// Logbook route.
  static const logbook = '/logbook';

  /// Notifications route.
  static const notifications = '/notifications';

  /// Profile route.
  static const profile = '/profile';

  /// Settings route.
  static const settings = '/settings';

  /// Lecturer assigned students route.
  static const assignedStudents = '/lecturer/assigned-students';

  /// Lecturer visit reports route.
  static const visitReports = '/lecturer/visit-reports';

  /// Lecturer student detail route (FR-SUP-002).
  static const studentDetail = '/lecturer/student-detail';

  /// Coordinator students route.
  static const students = '/coordinator/students';

  /// Coordinator lecturers route.
  static const lecturers = '/coordinator/lecturers';

  /// Coordinator reports route.
  static const reports = '/coordinator/reports';
}
