import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/constants/app_routes.dart';
import 'package:servio/app/shell/app_shell.dart';
import 'package:servio/app/theme/app_theme.dart';
import 'package:servio/core/enums/user_role.dart';
import 'package:servio/features/authentication/data/models/auth_session.dart';
import 'package:servio/features/authentication/presentation/providers/authentication_providers.dart';

/// A signed-out session, so the shell renders without touching Firebase.
final _signedOut = authSessionProvider.overrideWith(
  (ref) => Stream.value(
    const AuthSession(firebaseUser: null, isEmailVerified: false),
  ),
);

Widget _shell({required String path, bool showBack = false}) {
  return ProviderScope(
    overrides: [_signedOut],
    child: MaterialApp(
      theme: AppTheme.light,
      home: AppShell(
        role: UserRole.coordinator,
        currentPath: path,
        title: 'Students',
        showBack: showBack,
        child: const Text('Section body'),
      ),
    ),
  );
}

/// Sets the logical screen size the shell sees through MediaQuery.
void _setScreen(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('ShellDestination.indexFor', () {
    final coordinator = ShellDestination.forRole(UserRole.coordinator);

    test('matches a section exactly', () {
      expect(ShellDestination.indexFor(coordinator, AppRoutes.students), 1);
    });

    test('matches a detail page to its parent section', () {
      expect(
        ShellDestination.indexFor(
          coordinator,
          AppRoutes.coordinatorStudentDetail('abc'),
        ),
        1,
      );
    });

    test('does not match a path that only shares a prefix', () {
      // /coordinator/studentsX is not under /coordinator/students.
      expect(
        ShellDestination.indexFor(coordinator, '/coordinator/studentsX'),
        -1,
      );
    });

    test('gives every role four sections', () {
      for (final role in UserRole.values) {
        expect(ShellDestination.forRole(role), hasLength(4), reason: '$role');
      }
    });
  });

  group('AppShell layout', () {
    testWidgets('uses a bottom bar on phones', (tester) async {
      _setScreen(tester, const Size(390, 800));

      await tester.pumpWidget(_shell(path: AppRoutes.students));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Section body'), findsOneWidget);
    });

    testWidgets('uses a sidebar on laptops', (tester) async {
      _setScreen(tester, const Size(1280, 800));

      await tester.pumpWidget(_shell(path: AppRoutes.students));
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Lecturers'), findsOneWidget);
      expect(find.text('Section body'), findsOneWidget);
    });

    testWidgets('detail pages show a back button instead of the bottom bar', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 800));

      await tester.pumpWidget(
        _shell(path: AppRoutes.coordinatorStudentDetail('abc'), showBack: true),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });
}
