import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_screen.dart';
import '../../features/authentication/presentation/providers/authentication_providers.dart';
import '../../features/authentication/presentation/screens/email_verification_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/widgets/authenticated_placeholder_screen.dart';
import '../constants/app_routes.dart';
import 'auth_redirects.dart';

/// Provides the configured GoRouter for Servio.
final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionValue = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = switch (sessionValue) {
        AsyncData(:final value) => value,
        _ => null,
      };
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
        builder: (context, state) => const AuthenticatedPlaceholderScreen(
          title: 'Student Dashboard',
          description:
              'Student summary widgets will be added during dashboard implementation.',
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
        builder: (context, state) => const AuthenticatedPlaceholderScreen(
          title: 'Coordinator Dashboard',
          description:
              'Coordinator administrative summaries will be added later.',
        ),
      ),
      _placeholder(
        AppRoutes.internship,
        'Internship',
        'Placement lifecycle screens will live here.',
      ),
      _placeholder(
        AppRoutes.attendance,
        'Attendance',
        'Check-in, checkout, and history screens will live here.',
      ),
      _placeholder(
        AppRoutes.logbook,
        'Logbook',
        'Digital logbook screens will live here.',
      ),
      _placeholder(
        AppRoutes.notifications,
        'Notifications',
        'Notification list and read states will live here.',
      ),
      _placeholder(
        AppRoutes.profile,
        'Profile',
        'User profile screens will live here.',
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

GoRoute _placeholder(String path, String title, String description) {
  return GoRoute(
    path: path,
    builder: (context, state) =>
        AuthenticatedPlaceholderScreen(title: title, description: description),
  );
}
