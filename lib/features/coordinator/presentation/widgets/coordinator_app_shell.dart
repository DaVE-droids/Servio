import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../notifications/presentation/widgets/notifications_bell_button.dart';

/// A top-level coordinator section.
class CoordinatorDestination {
  const CoordinatorDestination._(
    this.label,
    this.icon,
    this.selectedIcon,
    this.route,
  );

  /// Label shown in the navigation bar or rail.
  final String label;

  /// Icon when not selected.
  final IconData icon;

  /// Icon when selected.
  final IconData selectedIcon;

  /// Route for this section.
  final String route;

  /// The coordinator's four sections, in navigation order (PRD §18:
  /// dashboard/placement approval, student management, lecturer
  /// management, reports).
  static const values = [
    CoordinatorDestination._(
      'Placements',
      Icons.assignment_outlined,
      Icons.assignment,
      AppRoutes.coordinatorDashboard,
    ),
    CoordinatorDestination._(
      'Students',
      Icons.school_outlined,
      Icons.school,
      AppRoutes.students,
    ),
    CoordinatorDestination._(
      'Lecturers',
      Icons.badge_outlined,
      Icons.badge,
      AppRoutes.lecturers,
    ),
    CoordinatorDestination._(
      'Reports',
      Icons.summarize_outlined,
      Icons.summarize,
      AppRoutes.reports,
    ),
  ];

  /// Index of the section a path belongs to (0 if none matches).
  static int indexForPath(String path) {
    final index = values.indexWhere((destination) => destination.route == path);
    return index < 0 ? 0 : index;
  }
}

/// Coordinator application shell, matching the student shell's pattern:
/// a bottom navigation bar on phones and a side rail from 600px up, so the
/// same build works on a laptop browser.
///
/// Audit history, notifications, and profile are secondary destinations,
/// so they sit in the app bar and open on top of the current section.
class CoordinatorAppShell extends ConsumerWidget {
  /// Creates the coordinator app shell.
  const CoordinatorAppShell({
    required this.currentPath,
    required this.title,
    required this.child,
    super.key,
  });

  /// Current route path, used to highlight the active section.
  final String currentPath;

  /// App bar title.
  final String title;

  /// The section's content.
  final Widget child;

  static const double _railBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationControllerProvider);
    final selectedIndex = CoordinatorDestination.indexForPath(currentPath);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= _railBreakpoint;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.audit),
                icon: const Icon(Icons.history),
                tooltip: 'Audit History',
              ),
              const NotificationsBellButton(),
              IconButton(
                onPressed: () => context.push(AppRoutes.profile),
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profile',
              ),
              IconButton(
                onPressed: authState.isLoading
                    ? null
                    : () => ref
                          .read(authenticationControllerProvider.notifier)
                          .logout(),
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) => _go(context, index),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final destination in CoordinatorDestination.values)
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
                  onDestinationSelected: (index) => _go(context, index),
                  destinations: [
                    for (final destination in CoordinatorDestination.values)
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

  void _go(BuildContext context, int index) {
    final route = CoordinatorDestination.values[index].route;
    if (route != currentPath) {
      context.go(route);
    }
  }
}
