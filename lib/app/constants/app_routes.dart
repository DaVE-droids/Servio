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

  /// Email verification route.
  static const verification = '/verification';

  /// Shown to a lecturer whose account a coordinator hasn't approved yet.
  static const pendingApproval = '/pending-approval';

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

  /// Lecturer assigned students route.
  static const assignedStudents = '/lecturer/assigned-students';

  /// Lecturer student detail route pattern (FR-SUP-002). The internship
  /// ID is in the URL, so the page survives a browser refresh.
  static const lecturerStudentDetailPattern =
      '/lecturer/students/:internshipId';

  /// Lecturer student detail path for a specific placement.
  static String lecturerStudentDetail(String internshipId) =>
      '/lecturer/students/$internshipId';

  /// Lecturer visit report route pattern (FR-SUP-004), nested under the
  /// student it's for.
  static const lecturerVisitReportPattern = 'visit';

  /// Lecturer visit report path for a specific placement.
  static String lecturerVisitReport(String internshipId) =>
      '/lecturer/students/$internshipId/visit';

  /// Coordinator students route.
  static const students = '/coordinator/students';

  /// Coordinator student detail route pattern (`:studentId` is the UID).
  static const coordinatorStudentDetailPattern =
      '/coordinator/students/:studentId';

  /// Coordinator student detail path for a specific student.
  static String coordinatorStudentDetail(String studentId) =>
      '/coordinator/students/$studentId';

  /// Coordinator lecturers route.
  static const lecturers = '/coordinator/lecturers';

  /// Coordinator lecturer detail route pattern (`:lecturerId` is the UID).
  static const coordinatorLecturerDetailPattern =
      '/coordinator/lecturers/:lecturerId';

  /// Coordinator lecturer detail path for a specific lecturer.
  static String coordinatorLecturerDetail(String lecturerId) =>
      '/coordinator/lecturers/$lecturerId';

  /// Coordinator reports route.
  static const reports = '/coordinator/reports';

  /// Coordinator audit history route (FR-AUDIT-004).
  static const audit = '/coordinator/audit';
}
