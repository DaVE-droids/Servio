import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/authentication_providers.dart';
import 'student_navigation_destination.dart';

/// Authenticated student application shell with adaptive navigation.
class StudentAppShell extends ConsumerWidget {
  /// Creates the student app shell.
  const StudentAppShell({
    required this.currentPath,
    required this.title,
    required this.child,
    super.key,
  });

  /// Current route path used to select the active destination.
  final String currentPath;

  /// Screen title shown in the app bar.
  final String title;

  /// Active screen content.
  final Widget child;

  static const double _navigationRailBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);
    final selectedIndex = StudentNavigationDestination.selectedIndexForPath(
      currentPath,
    );

    ref.listen(authenticationControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= _navigationRailBreakpoint;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              TextButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => ref
                          .read(authenticationControllerProvider.notifier)
                          .logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) =>
                          _goToDestination(context, index),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final destination
                            in StudentNavigationDestination.values)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: child),
                  ],
                )
              : child,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _goToDestination(context, index),
                  destinations: [
                    for (final destination
                        in StudentNavigationDestination.values)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }

  void _goToDestination(BuildContext context, int index) {
    final destination = StudentNavigationDestination.values[index];
    if (destination.route != currentPath) {
      context.go(destination.route);
    }
  }
}
