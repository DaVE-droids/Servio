import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio/app/theme/app_theme.dart';
import 'package:servio/core/widgets/brand_mark.dart';
import 'package:servio/features/authentication/data/models/auth_session.dart';
import 'package:servio/features/authentication/presentation/providers/authentication_providers.dart';
import 'package:servio/features/authentication/presentation/screens/splash_screen.dart';

Widget _splash(Stream<AuthSession> session) {
  return ProviderScope(
    overrides: [authSessionProvider.overrideWith((ref) => session)],
    child: MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
  );
}

void main() {
  testWidgets('waits quietly while the session is loading', (tester) async {
    // A stream that never emits: the normal few hundred milliseconds at
    // launch.
    await tester.pumpWidget(_splash(const Stream<AuthSession>.empty()));
    await tester.pump();

    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('offers a way out when the session cannot be loaded', (
    tester,
  ) async {
    // Without this, a failed account lookup left the app on a progress bar
    // that would never finish.
    await tester.pumpWidget(
      _splash(Stream<AuthSession>.error(Exception('offline'))),
    );
    // One frame to subscribe, one for the error to arrive.
    await tester.pump();
    await tester.pump();

    expect(find.text('We couldn’t load your account'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
