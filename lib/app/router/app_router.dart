import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/user_role.dart';
import '../../features/authentication/data/models/auth_session.dart';
import '../../features/authentication/presentation/providers/authentication_providers.dart';
import '../../features/authentication/presentation/screens/email_verification_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/pending_approval_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/widgets/authenticated_placeholder_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_screen.dart';
import '../../features/audit/presentation/screens/coordinator_audit_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_dashboard_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_lecturer_detail_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_lecturers_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_reports_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_student_detail_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_students_screen.dart';
import '../../features/coordinator/presentation/widgets/coordinator_app_shell.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/student_app_shell.dart';
import '../../features/internship/data/models/internship_model.dart';
import '../../features/internship/presentation/screens/student_internship_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_assigned_students_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_attendance_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_dashboard_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_logbook_review_screen.dart';
import '../../features/lecturer/presentation/screens/lecturer_student_detail_screen.dart';
import '../../features/logbook/presentation/screens/student_logbook_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/data/models/user_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/supervision/presentation/screens/lecturer_visit_report_screen.dart';
import '../constants/app_routes.dart';
import 'auth_redirects.dart';

/// Provides the configured GoRouter for Servio.
final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionValue = ref.watch(authSessionProvider);
  final session = switch (sessionValue) {
    AsyncData(:final value) => value,
    _ => null,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      return AuthRedirects.redirectFor(
        path: path,
        session: session,
        isSessionLoading: sessionValue.isLoading,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
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
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentDashboard,
        pageBuilder: (context, state) => NoTransitionPage(
          child: _studentShell(
            path: state.uri.path,
            title: 'Dashboard',
            child: const StudentDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.lecturerDashboard,
        builder: (context, state) {
          if (session?.role != UserRole.lecturer) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Lecturer Dashboard',
              description:
                  'Lecturer supervision summary widgets will be added later.',
            );
          }
          return const LecturerDashboardScreen();
        },
      ),
      // Coordinator sections share one shell. NoTransitionPage because
      // switching sections is a tab change, not drilling in.
      _coordinatorSection(
        session: session,
        path: AppRoutes.coordinatorDashboard,
        title: 'Placements',
        child: const CoordinatorDashboardScreen(),
      ),
      _coordinatorSection(
        session: session,
        path: AppRoutes.students,
        title: 'Students',
        child: const CoordinatorStudentsScreen(),
      ),
      _coordinatorSection(
        session: session,
        path: AppRoutes.lecturers,
        title: 'Lecturers',
        child: const CoordinatorLecturersScreen(),
      ),
      _coordinatorSection(
        session: session,
        path: AppRoutes.reports,
        title: 'Reports',
        child: const CoordinatorReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.coordinatorStudentDetailPattern,
        builder: (context, state) => CoordinatorStudentDetailScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.coordinatorLecturerDetailPattern,
        builder: (context, state) => CoordinatorLecturerDetailScreen(
          lecturerId: state.pathParameters['lecturerId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.internship,
        builder: (context, state) {
          if (session?.role != UserRole.student) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Internship',
              description: 'Placement lifecycle screens will live here.',
            );
          }
          return _studentShell(
            path: state.uri.path,
            title: 'Internship',
            child: const StudentInternshipScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.attendance,
        pageBuilder: (context, state) {
          if (session?.role == UserRole.lecturer) {
            // Reached via push() from the lecturer dashboard, not a tab
            // switch, so this keeps the default "drilling in" transition.
            return MaterialPage(child: const LecturerAttendanceScreen());
          }
          if (session?.role != UserRole.student) {
            return NoTransitionPage(
              child: const AuthenticatedPlaceholderScreen(
                title: 'Attendance',
                description: 'Attendance screens will live here.',
              ),
            );
          }
          return NoTransitionPage(
            child: _studentShell(
              path: state.uri.path,
              title: 'Attendance',
              child: const StudentAttendanceScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.logbook,
        pageBuilder: (context, state) {
          if (session?.role == UserRole.lecturer) {
            // Reached via push() from the lecturer dashboard, not a tab
            // switch, so this keeps the default "drilling in" transition.
            return MaterialPage(child: const LecturerLogbookReviewScreen());
          }
          if (session?.role != UserRole.student) {
            return NoTransitionPage(
              child: const AuthenticatedPlaceholderScreen(
                title: 'Logbook',
                description: 'Digital logbook screens will live here.',
              ),
            );
          }
          return NoTransitionPage(
            child: _studentShell(
              path: state.uri.path,
              title: 'Logbook',
              child: const StudentLogbookScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) {
          if (session?.role != UserRole.student) {
            // Reached via push() from a non-student dashboard, not a tab
            // switch, so this keeps the default "drilling in" transition.
            return MaterialPage(child: const NotificationsScreen());
          }
          return NoTransitionPage(
            child: _studentShell(
              path: state.uri.path,
              title: 'Notifications',
              child: const NotificationsScreen(showScaffold: false),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          if (session?.role != UserRole.student) {
            // Reached via push() from a non-student dashboard, not a tab
            // switch, so this keeps the default "drilling in" transition.
            return MaterialPage(child: const ProfileScreen());
          }
          return NoTransitionPage(
            child: _studentShell(
              path: state.uri.path,
              title: 'Profile',
              child: const ProfileScreen(showScaffold: false),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.assignedStudents,
        builder: (context, state) {
          if (session?.role != UserRole.lecturer) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Assigned Students',
              description: 'Lecturer assigned student list will live here.',
            );
          }
          return const LecturerAssignedStudentsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.studentDetail,
        builder: (context, state) {
          if (session?.role != UserRole.lecturer) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Student Detail',
              description: 'Lecturer student detail will live here.',
            );
          }
          final internship = state.extra as InternshipModel;
          return LecturerStudentDetailScreen(internship: internship);
        },
      ),
      GoRoute(
        path: AppRoutes.visitReports,
        builder: (context, state) {
          if (session?.role != UserRole.lecturer) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Visit Reports',
              description: 'Supervision visit report screens will live here.',
            );
          }
          final (internship, student) =
              state.extra as (InternshipModel, UserModel);
          return LecturerVisitReportScreen(
            internship: internship,
            student: student,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.audit,
        builder: (context, state) {
          if (session?.role != UserRole.coordinator) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Audit History',
              description: 'Audit history is available to coordinators.',
            );
          }
          return const CoordinatorAuditScreen();
        },
      ),
    ],
  );
});

Widget _studentShell({
  required String path,
  required String title,
  required Widget child,
}) {
  return StudentAppShell(currentPath: path, title: title, child: child);
}

/// A top-level coordinator section wrapped in the coordinator shell.
///
/// The role check is a fallback only — [AuthRedirects] already keeps other
/// roles off `/coordinator/...` paths before this builder runs.
GoRoute _coordinatorSection({
  required AuthSession? session,
  required String path,
  required String title,
  required Widget child,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage(
      child: session?.role != UserRole.coordinator
          ? AuthenticatedPlaceholderScreen(
              title: title,
              description: 'This section is available to coordinators.',
            )
          : CoordinatorAppShell(
              currentPath: state.uri.path,
              title: title,
              child: child,
            ),
    ),
  );
}
