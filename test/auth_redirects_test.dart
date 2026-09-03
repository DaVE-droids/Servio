import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/constants/app_routes.dart';
import 'package:servio/app/router/auth_redirects.dart';
import 'package:servio/core/enums/user_role.dart';
import 'package:servio/features/authentication/data/models/auth_session.dart';

/// Tests authentication guards and role-based route permissions.
void main() {
  group('AuthRedirects', () {
    test('keeps loading users on splash', () {
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.login,
          session: null,
          isSessionLoading: true,
        ),
        AppRoutes.splash,
      );
    });

    test('allows signed-out users to access auth routes only', () {
      const session = AuthSession(firebaseUser: null, isEmailVerified: false);

      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.login,
          session: session,
          isSessionLoading: false,
        ),
        isNull,
      );
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.attendance,
          session: session,
          isSessionLoading: false,
        ),
        AppRoutes.login,
      );
    });

    test('maps roles to dashboards', () {
      expect(
        AuthRedirects.dashboardForRole(UserRole.student),
        AppRoutes.studentDashboard,
      );
      expect(
        AuthRedirects.dashboardForRole(UserRole.lecturer),
        AppRoutes.lecturerDashboard,
      );
      expect(
        AuthRedirects.dashboardForRole(UserRole.coordinator),
        AppRoutes.coordinatorDashboard,
      );
    });

    test('restricts cross-role destinations', () {
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.attendance,
          UserRole.student,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.students,
          UserRole.student,
        ),
        isFalse,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.students,
          UserRole.coordinator,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.assignedStudents,
          UserRole.lecturer,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.studentDetail,
          UserRole.lecturer,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.visitReports,
          UserRole.lecturer,
        ),
        isTrue,
      );
    });
  });
}
