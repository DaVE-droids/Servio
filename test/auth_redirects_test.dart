import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/constants/app_routes.dart';
import 'package:servio/app/router/auth_redirects.dart';
import 'package:servio/core/enums/user_role.dart';
import 'package:servio/features/authentication/data/models/auth_session.dart';

/// A signed-in Firebase user, which is all the redirect rules look at.
class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

AuthSession _signedIn(UserRole role, {String uid = 'u1'}) => AuthSession(
  firebaseUser: _FakeUser(uid),
  isEmailVerified: true,
  role: role,
);

/// Tests authentication guards and role-based route permissions.
void main() {
  group('AuthRedirects', () {
    test('flags only unapproved lecturers as awaiting approval', () {
      const session = AuthSession(
        firebaseUser: null,
        isEmailVerified: true,
        role: UserRole.lecturer,
        isActive: false,
      );
      expect(session.isAwaitingApproval, isTrue);
      // firebaseUser is null here, so the session reads as signed out; the
      // approval flag itself is what the router keys on once signed in.
      const activeLecturer = AuthSession(
        firebaseUser: null,
        isEmailVerified: true,
        role: UserRole.lecturer,
      );
      expect(activeLecturer.isAwaitingApproval, isFalse);
      const inactiveStudent = AuthSession(
        firebaseUser: null,
        isEmailVerified: true,
        role: UserRole.student,
        isActive: false,
      );
      expect(
        inactiveStudent.isAwaitingApproval,
        isFalse,
        reason: 'only lecturers go through coordinator approval',
      );
    });

    test('allows coordinator detail pages that carry an ID in the path', () {
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.coordinatorStudentDetail('abc123'),
          UserRole.coordinator,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.coordinatorLecturerDetail('abc123'),
          UserRole.lecturer,
        ),
        isFalse,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.reports,
          UserRole.student,
        ),
        isFalse,
      );
    });

    test('keeps loading users on splash', () {
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.login,
          session: null,
          isSessionLoading: true,
        ),
        '/?from=%2Flogin',
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
        '/login?from=%2Fattendance',
        reason: 'the page asked for is remembered for after sign-in',
      );
    });

    test('remembers a deep link while the session loads', () {
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.coordinatorStudentDetail('abc'),
          session: null,
          isSessionLoading: true,
        ),
        '/?from=%2Fcoordinator%2Fstudents%2Fabc',
      );
    });

    test('a signed-out visitor following a sign-up link reaches sign-up', () {
      const signedOut = AuthSession(firebaseUser: null, isEmailVerified: false);
      final whileLoading = AuthRedirects.redirectFor(
        path: AppRoutes.register,
        session: null,
        isSessionLoading: true,
      );
      expect(whileLoading, '/?from=%2Fregister');
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.splash,
          session: signedOut,
          isSessionLoading: false,
          from: AppRoutes.register,
        ),
        AppRoutes.register,
      );
    });

    test('returns a signed-in user to the page they asked for', () {
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.splash,
          session: _signedIn(UserRole.coordinator),
          isSessionLoading: false,
          from: AppRoutes.coordinatorStudentDetail('abc'),
        ),
        '/coordinator/students/abc',
      );
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.login,
          session: _signedIn(UserRole.student),
          isSessionLoading: false,
          from: AppRoutes.logbook,
        ),
        AppRoutes.logbook,
      );
    });

    test('ignores a remembered page the role may not open', () {
      expect(
        AuthRedirects.redirectFor(
          path: AppRoutes.splash,
          session: _signedIn(UserRole.student),
          isSessionLoading: false,
          from: AppRoutes.reports,
        ),
        AppRoutes.studentDashboard,
      );
    });

    test('ignores remembered targets that are not in-app paths', () {
      for (final from in ['//evil.example', 'https://evil.example', '']) {
        expect(
          AuthRedirects.redirectFor(
            path: AppRoutes.splash,
            session: _signedIn(UserRole.student),
            isSessionLoading: false,
            from: from,
          ),
          AppRoutes.studentDashboard,
          reason: from,
        );
      }
    });

    test('treats sessions with the same access as equal', () {
      // Firebase hands back a new User object on every token refresh; the
      // session must still compare equal so nothing reloads.
      expect(_signedIn(UserRole.student), _signedIn(UserRole.student));
      expect(
        _signedIn(UserRole.student) == _signedIn(UserRole.student, uid: 'u2'),
        isFalse,
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
          AppRoutes.lecturerStudentDetail('i1'),
          UserRole.lecturer,
        ),
        isTrue,
      );
      expect(
        AuthRedirects.isRouteAllowedForRole(
          AppRoutes.lecturerVisitReport('i1'),
          UserRole.lecturer,
        ),
        isTrue,
      );
    });
  });
}
