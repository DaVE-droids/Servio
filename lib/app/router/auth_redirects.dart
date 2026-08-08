import '../../core/enums/user_role.dart';
import '../../features/authentication/data/models/auth_session.dart';
import '../constants/app_routes.dart';

/// Route policy helpers for authentication and role-based navigation.
abstract final class AuthRedirects {
  /// Returns the correct dashboard route for a Servio role.
  static String? dashboardForRole(UserRole? role) {
    return switch (role) {
      UserRole.student => AppRoutes.studentDashboard,
      UserRole.lecturer => AppRoutes.lecturerDashboard,
      UserRole.coordinator => AppRoutes.coordinatorDashboard,
      null => null,
    };
  }

  /// Returns whether a route is allowed for the given role.
  static bool isRouteAllowedForRole(String path, UserRole? role) {
    final sharedRoutes = {
      AppRoutes.notifications,
      AppRoutes.profile,
      AppRoutes.settings,
    };
    if (sharedRoutes.contains(path)) {
      return true;
    }

    return switch (role) {
      UserRole.student => {
        AppRoutes.studentDashboard,
        AppRoutes.internship,
        AppRoutes.attendance,
        AppRoutes.logbook,
      }.contains(path),
      UserRole.lecturer => {
        AppRoutes.lecturerDashboard,
        AppRoutes.assignedStudents,
        AppRoutes.visitReports,
        AppRoutes.logbook,
      }.contains(path),
      UserRole.coordinator => {
        AppRoutes.coordinatorDashboard,
        AppRoutes.students,
        AppRoutes.lecturers,
        AppRoutes.internship,
        AppRoutes.reports,
      }.contains(path),
      null => false,
    };
  }

  /// Computes the redirect target for the current route and session.
  static String? redirectFor({
    required String path,
    required AuthSession? session,
    required bool isSessionLoading,
  }) {
    final isAuthRoute = {
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
    }.contains(path);

    if (isSessionLoading || session == null) {
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    }

    if (!session.isAuthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    if (!session.isEmailVerified) {
      return path == AppRoutes.verification ? null : AppRoutes.verification;
    }

    final roleDashboard = dashboardForRole(session.role);
    if (roleDashboard == null) {
      return AppRoutes.login;
    }

    if (isAuthRoute ||
        path == AppRoutes.splash ||
        path == AppRoutes.verification) {
      return roleDashboard;
    }

    if (!isRouteAllowedForRole(path, session.role)) {
      return roleDashboard;
    }

    return null;
  }
}
