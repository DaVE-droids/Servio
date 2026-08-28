import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servio/app/constants/app_routes.dart';
import 'package:servio/app/theme/app_theme.dart';
import 'package:servio/features/dashboard/presentation/widgets/student_app_shell.dart';

void main() {
  testWidgets('uses bottom navigation on phone widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudentAppShell(
            currentPath: AppRoutes.studentDashboard,
            title: 'Dashboard',
            child: Text('Student dashboard body'),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Student dashboard body'), findsOneWidget);
  });

  testWidgets('uses navigation rail on tablet and desktop widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StudentAppShell(
            currentPath: AppRoutes.profile,
            title: 'Profile',
            child: Text('Profile body'),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Profile body'), findsOneWidget);
  });
}
