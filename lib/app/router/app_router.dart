import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/user_role.dart';
import '../../features/attendance/presentation/screens/student_attendance_screen.dart';
import '../../features/audit/presentation/screens/coordinator_audit_screen.dart';
import '../../features/authentication/data/models/auth_session.dart';
import '../../features/authentication/presentation/providers/authentication_providers.dart';
import '../../features/authentication/presentation/screens/email_verification_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/pending_approval_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_dashboard_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_lecturer_detail_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_lecturers_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_reports_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_student_detail_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_students_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/internship/presentation/screens/student_internship_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_assigned_students_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_attendance_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_dashboard_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_logbook_review_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_student_detail_screen.dart';
import '../../features/logbook/presentation/screens/student_logbook_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/supervision/presentation/screens/lecturer_visit_report_screen.dart';
import '../constants/app_routes.dart';
import '../shell/app_shell.dart';
import '../shell/not_found_screen.dart';
import 'auth_redirects.dart';

/// Provides the app's single [GoRouter].
///
/// The router is created once. When the session changes in a way that
/// affects where the user may be — signing in or out, verifying their
/// email, being approved — [refreshListenable] makes it re-check its
/// redirects in place. (It used to be rebuilt on every session event,
/// including Firebase's hourly token refresh, which threw users back to
/// their dashboard mid-task.)
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (previous, next) {
    if (previous?.value != next.value ||
        _isResolving(previous) != _isResolving(next)) {
      refresh.value++;
    }
  });

  AuthSession? session() => ref.read(authSessionProvider).value;
  UserRole? role() => session()?.role;

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => AuthRedirects.redirectFor(
      path: state.uri.path,
      session: session(),
      isSessionLoading: _isResolving(ref.read(authSessionProvider)),
      from: state.uri.queryParameters[AuthRedirects.fromParam],
    ),
    errorPageBuilder: (context, state) =>
        const NoTransitionPage(child: NotFoundScreen()),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: EmailVerificationScreen()),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PendingApprovalScreen()),
      ),

      // Student sections.
      _section(AppRoutes.studentDashboard, 'Home', role, (_) {
        return const StudentDashboardScreen();
      }),
      _section(AppRoutes.internship, 'Placement', role, (_) {
        return const StudentInternshipScreen();
      }),

      // Attendance and the logbook are sections for both students and
      // lecturers, showing each role its own side of the same records.
      _section(
        AppRoutes.attendance,
        'Attendance',
        role,
        (role) => role == UserRole.lecturer
            ? const LecturerAttendanceScreen()
            : const StudentAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.logbook,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: AppShell(
            role: role(),
            currentPath: state.uri.path,
            title: role() == UserRole.lecturer ? 'Logbook reviews' : 'Logbook',
            child: role() == UserRole.lecturer
                ? const LecturerLogbookReviewScreen()
                : const StudentLogbookScreen(),
          ),
        ),
      ),

      // Lecturer sections and pages.
      _section(AppRoutes.lecturerDashboard, 'Home', role, (_) {
        return const LecturerDashboardScreen();
      }),
      _section(AppRoutes.assignedStudents, 'My students', role, (_) {
        return const LecturerAssignedStudentsScreen();
      }),
      GoRoute(
        path: AppRoutes.lecturerStudentDetailPattern,
        pageBuilder: (context, state) => _detail(
          state,
          role(),
          'Student details',
          LecturerStudentDetailScreen(
            internshipId: state.pathParameters['internshipId']!,
          ),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.lecturerVisitReportPattern,
            pageBuilder: (context, state) => _detail(
              state,
              role(),
              'New visit report',
              LecturerVisitReportScreen(
                internshipId: state.pathParameters['internshipId']!,
              ),
            ),
          ),
        ],
      ),

      // Coordinator sections and pages.
      _section(AppRoutes.coordinatorDashboard, 'Placements', role, (_) {
        return const CoordinatorDashboardScreen();
      }),
      _section(AppRoutes.students, 'Students', role, (_) {
        return const CoordinatorStudentsScreen();
      }),
      _section(AppRoutes.lecturers, 'Lecturers', role, (_) {
        return const CoordinatorLecturersScreen();
      }),
      _section(AppRoutes.reports, 'Reports', role, (_) {
        return const CoordinatorReportsScreen();
      }),
      GoRoute(
        path: AppRoutes.coordinatorStudentDetailPattern,
        pageBuilder: (context, state) => _detail(
          state,
          role(),
          'Student details',
          CoordinatorStudentDetailScreen(
            studentId: state.pathParameters['studentId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.coordinatorLecturerDetailPattern,
        pageBuilder: (context, state) => _detail(
          state,
          role(),
          'Lecturer details',
          CoordinatorLecturerDetailScreen(
            lecturerId: state.pathParameters['lecturerId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.audit,
        pageBuilder: (context, state) => _detail(
          state,
          role(),
          'Audit history',
          const CoordinatorAuditScreen(),
        ),
      ),

      // Shared by every role.
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _detail(
          state,
          role(),
          'Notifications',
          const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            _detail(state, role(), 'Profile', const ProfileScreen()),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Still waiting for the first session value (a refresh that already has a
/// previous value doesn't count, so the current page stays put).
bool _isResolving(AsyncValue<AuthSession>? value) =>
    value == null || (value.isLoading && !value.hasValue);

/// A top-level section: shown in the shell, switched to without a
/// transition because it's a tab change, not drilling in.
GoRoute _section(
  String path,
  String title,
  UserRole? Function() role,
  Widget Function(UserRole? role) screen,
) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: AppShell(
        role: role(),
        currentPath: state.uri.path,
        title: title,
        child: screen(role()),
      ),
    ),
  );
}

/// A page opened on top of a section, with a back button.
Page<void> _detail(
  GoRouterState state,
  UserRole? role,
  String title,
  Widget screen,
) {
  return MaterialPage(
    key: state.pageKey,
    child: AppShell(
      role: role,
      currentPath: state.uri.path,
      title: title,
      showBack: true,
      child: screen,
    ),
  );
}
