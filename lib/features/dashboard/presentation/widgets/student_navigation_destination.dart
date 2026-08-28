import 'package:flutter/material.dart';

import '../../../../app/constants/app_routes.dart';

/// A destination in the authenticated student navigation shell.
class StudentNavigationDestination {
  /// Creates a student navigation destination.
  const StudentNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  /// Destination label shown in navigation components.
  final String label;

  /// Icon shown when the destination is not selected.
  final IconData icon;

  /// Icon shown when the destination is selected.
  final IconData selectedIcon;

  /// Route path associated with this destination.
  final String route;

  /// Student navigation destinations defined by the DSS.
  static const values = [
    StudentNavigationDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: AppRoutes.studentDashboard,
    ),
    StudentNavigationDestination(
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      route: AppRoutes.attendance,
    ),
    StudentNavigationDestination(
      label: 'Logbook',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: AppRoutes.logbook,
    ),
    StudentNavigationDestination(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      route: AppRoutes.notifications,
    ),
    StudentNavigationDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: AppRoutes.profile,
    ),
  ];

  /// Returns the selected destination index for a route path.
  static int selectedIndexForPath(String path) {
    final index = values.indexWhere((destination) => destination.route == path);
    return index < 0 ? 0 : index;
  }
}
