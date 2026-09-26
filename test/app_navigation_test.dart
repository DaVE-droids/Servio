import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:servio/app/router/app_navigation.dart';

/// The bell, the account menu, and the audit history sit in the top bar of
/// every screen, including the screens they open. Tapping one repeatedly
/// used to stack a copy per tap, so four taps meant four presses of Back.
void main() {
  late GoRouter router;

  Widget bell(String target) => Builder(
    builder: (context) => TextButton(
      onPressed: () => context.pushUnlessCurrent(target),
      child: const Text('bell'),
    ),
  );

  setUp(() {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: [bell('/notifications')]),
            body: const Text('home page'),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: [bell('/notifications')]),
            body: const Text('notifications page'),
          ),
        ),
      ],
    );
  });

  /// How many pages are stacked; one Back press pops one of them.
  int stackDepth() =>
      router.routerDelegate.currentConfiguration.matches.length;

  Future<void> tapBell(WidgetTester tester, {int times = 1}) async {
    for (var tap = 0; tap < times; tap++) {
      await tester.tap(find.text('bell'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('opens once however many times it is tapped', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(stackDepth(), 1);

    await tapBell(tester, times: 4);

    expect(find.text('notifications page'), findsOneWidget);
    expect(stackDepth(), 2, reason: 'the home page plus one notifications');
  });

  testWidgets('one Back returns to where you were', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tapBell(tester, times: 4);
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('home page'), findsOneWidget);
    expect(find.text('notifications page'), findsNothing);
    expect(stackDepth(), 1);
  });

  testWidgets('still opens the page when you are somewhere else', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tapBell(tester);

    expect(find.text('notifications page'), findsOneWidget);
    expect(stackDepth(), 2);
  });
}
