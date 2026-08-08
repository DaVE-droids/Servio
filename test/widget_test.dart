import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servio/app/router/app_router.dart';
import 'package:servio/app/app.dart';
import 'package:servio/core/widgets/placeholder_screen.dart';

/// Verifies that the Servio application shell renders its initial route.
void main() {
  testWidgets('Servio app shell renders', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Servio',
            description: 'Test shell',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const ServioApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Servio'), findsWidgets);
  });
}
