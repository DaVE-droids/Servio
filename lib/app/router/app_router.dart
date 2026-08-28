import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/user_role.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../features/authentication/presentation/providers/authentication_providers.dart';
import '../../features/authentication/presentation/screens/email_verification_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/widgets/authenticated_placeholder_screen.dart';
import '../../features/coordinator/presentation/screens/coordinator_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/student_coming_soon_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/student_app_shell.dart';
import '../../features/internship/presentation/screens/student_internship_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
        builder: (context, state) => const PlaceholderScreen(
          title: 'Servio',
          description:
              'Application startup and authentication checks will live here.',
        ),
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
        path: AppRoutes.studentDashboard,
        builder: (context, state) => _studentShell(
          path: state.uri.path,
          title: 'Dashboard',
          child: const StudentDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.lecturerDashboard,
        builder: (context, state) => const AuthenticatedPlaceholderScreen(
          title: 'Lecturer Dashboard',
          description:
              'Lecturer supervision summary widgets will be added later.',
        ),
      ),
      GoRoute(
        path: AppRoutes.coordinatorDashboard,
        builder: (context, state) {
          if (session?.role != UserRole.coordinator) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Coordinator Dashboard',
              description:
                  'Coordinator administrative summaries will be added later.',
            );
          }
          return const CoordinatorDashboardScreen();
        },
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
        builder: (context, state) => _studentShell(
          path: state.uri.path,
          title: 'Attendance',
          child: const StudentComingSoonScreen(
            title: 'Attendance Coming Soon',
            message:
                'Daily check-in, checkout, and attendance history will be available in the attendance module.',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.logbook,
        builder: (context, state) {
          if (session?.role != UserRole.student) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Logbook',
              description: 'Digital logbook screens will live here.',
            );
          }
          return _studentShell(
            path: state.uri.path,
            title: 'Logbook',
            child: const StudentComingSoonScreen(
              title: 'Logbook Coming Soon',
              message:
                  'Daily log entries, review status, and lecturer comments will be available in the logbook module.',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) {
          if (session?.role != UserRole.student) {
            return const AuthenticatedPlaceholderScreen(
              title: 'Notifications',
              description: 'Notification list and read states will live here.',
            );
          }
          return _studentShell(
            path: state.uri.path,
            title: 'Notifications',
            child: const StudentComingSoonScreen(
              title: 'Notifications Coming Soon',
              message:
                  'Placement alerts, attendance reminders, and logbook updates will appear here.',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          if (session?.role != UserRole.student) {
            return const ProfileScreen();
          }
          return _studentShell(
            path: state.uri.path,
            title: 'Profile',
            child: const ProfileScreen(showScaffold: false),
          );
        },
      ),
      _placeholder(
        AppRoutes.settings,
        'Settings',
        'Application settings will live here.',
      ),
      _placeholder(
        AppRoutes.assignedStudents,
        'Assigned Students',
        'Lecturer assigned student list will live here.',
      ),
      _placeholder(
        AppRoutes.visitReports,
        'Visit Reports',
        'Supervision visit report screens will live here.',
      ),
      _placeholder(
        AppRoutes.students,
        'Students',
        'Coordinator student management screens will live here.',
      ),
      _placeholder(
        AppRoutes.lecturers,
        'Lecturers',
        'Coordinator lecturer management screens will live here.',
      ),
      _placeholder(
        AppRoutes.reports,
        'Reports',
        'Coordinator report placeholders will live here.',
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

GoRoute _placeholder(String path, String title, String description) {
  return GoRoute(
    path: path,
    builder: (context, state) =>
        AuthenticatedPlaceholderScreen(title: title, description: description),
  );
}
