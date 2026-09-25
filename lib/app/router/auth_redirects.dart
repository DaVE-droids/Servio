import '../../core/enums/user_role.dart';
import '../../features/authentication/data/models/auth_session.dart';
import '../constants/app_routes.dart';

/// Route policy helpers for authentication and role-based navigation.
abstract final class AuthRedirects {
  /// Query parameter that carries the page a user was trying to open while
  /// the session loaded or they signed in.
  static const fromParam = 'from';

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
    final sharedRoutes = {AppRoutes.notifications, AppRoutes.profile};
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
      // Prefix checks (rather than listing each path) let detail pages
      // carry an ID in the URL, like /lecturer/students/<id>.
      UserRole.lecturer =>
        path.startsWith('/lecturer/') ||
            path == AppRoutes.logbook ||
            path == AppRoutes.attendance,
      // Coordinators don't submit placements, so /internship isn't theirs.
      UserRole.coordinator => path.startsWith('/coordinator/'),
      null => false,
    };
  }

  /// Computes the redirect target for the current route and session.
  ///
  /// [from] is the page the user originally asked for. It survives the
  /// splash screen and the login form, so refreshing a page in the browser
  /// — or following a link while signed out — lands the user back where
  /// they meant to go once their session is known.
  static String? redirectFor({
    required String path,
    required AuthSession? session,
    required bool isSessionLoading,
    String? from,
  }) {
    final isAuthRoute = {
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
    }.contains(path);
    final target = _safeTarget(from) ?? _safeTarget(path);

    if (isSessionLoading || session == null) {
      if (path == AppRoutes.splash) {
        return null;
      }
      // Remember sign-up and password-reset too, so a shared "/register"
      // link still opens sign-up once the (signed-out) session is known.
      return _withFrom(AppRoutes.splash, isAuthRoute ? path : target);
    }

    if (!session.isAuthenticated) {
      if (isAuthRoute) {
        return null;
      }
      if (path == AppRoutes.splash &&
          {AppRoutes.register, AppRoutes.forgotPassword}.contains(from)) {
        return from;
      }
      return _withFrom(AppRoutes.login, target);
    }

    if (!session.isEmailVerified) {
      return path == AppRoutes.verification ? null : AppRoutes.verification;
    }

    // A lecturer who signed up but hasn't been approved can go nowhere
    // else. The rules already deny them lecturer data; this just shows a
    // clear explanation instead of a dashboard full of permission errors.
    if (session.isAwaitingApproval) {
      return path == AppRoutes.pendingApproval
          ? null
          : AppRoutes.pendingApproval;
    }

    final roleDashboard = dashboardForRole(session.role);
    if (roleDashboard == null) {
      return AppRoutes.login;
    }

    if (isAuthRoute ||
        path == AppRoutes.splash ||
        path == AppRoutes.verification ||
        path == AppRoutes.pendingApproval) {
      return target != null && isRouteAllowedForRole(target, session.role)
          ? target
          : roleDashboard;
    }

    if (!isRouteAllowedForRole(path, session.role)) {
      return roleDashboard;
    }

    return null;
  }

  /// Keeps only in-app paths worth returning to. Rejects anything that
  /// isn't a plain absolute path (`//evil.example`, `https://…`), and the
  /// auth screens themselves, which are never a destination.
  static String? _safeTarget(String? path) {
    if (path == null || !path.startsWith('/') || path.startsWith('//')) {
      return null;
    }
    const notDestinations = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verification,
      AppRoutes.pendingApproval,
    };
    return notDestinations.contains(path) ? null : path;
  }

  static String _withFrom(String route, String? target) {
    if (target == null) {
      return route;
    }
    return Uri(path: route, queryParameters: {fromParam: target}).toString();
  }
}
