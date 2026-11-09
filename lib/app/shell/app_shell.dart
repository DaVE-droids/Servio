import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/user_role.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/brand_mark.dart';
import '../../features/authentication/presentation/providers/authentication_providers.dart';
import '../../features/notifications/presentation/widgets/notifications_bell_button.dart';
import '../../features/updates/presentation/widgets/update_prompt.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../constants/app_routes.dart';
import '../router/app_navigation.dart';
import '../router/auth_redirects.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// A top-level section in the navigation.
class ShellDestination {
  const ShellDestination(this.label, this.icon, this.selectedIcon, this.route);

  /// Label shown in the sidebar or bottom bar.
  final String label;

  /// Icon when not selected.
  final IconData icon;

  /// Icon when selected.
  final IconData selectedIcon;

  /// Route the section opens.
  final String route;

  /// Each role's sections, in order. Notifications and the profile are
  /// reached from the bell and the account menu, the same for every role.
  static List<ShellDestination> forRole(UserRole? role) => switch (role) {
    UserRole.student => const [
      ShellDestination(
        'Home',
        Icons.space_dashboard_outlined,
        Icons.space_dashboard,
        AppRoutes.studentDashboard,
      ),
      ShellDestination(
        'Placement',
        Icons.work_outline,
        Icons.work,
        AppRoutes.internship,
      ),
      ShellDestination(
        'Attendance',
        Icons.event_available_outlined,
        Icons.event_available,
        AppRoutes.attendance,
      ),
      ShellDestination(
        'Logbook',
        Icons.menu_book_outlined,
        Icons.menu_book,
        AppRoutes.logbook,
      ),
    ],
    UserRole.lecturer => const [
      ShellDestination(
        'Home',
        Icons.space_dashboard_outlined,
        Icons.space_dashboard,
        AppRoutes.lecturerDashboard,
      ),
      ShellDestination(
        'Students',
        Icons.groups_outlined,
        Icons.groups,
        AppRoutes.assignedStudents,
      ),
      ShellDestination(
        'Reviews',
        Icons.menu_book_outlined,
        Icons.menu_book,
        AppRoutes.logbook,
      ),
      ShellDestination(
        'Attendance',
        Icons.event_available_outlined,
        Icons.event_available,
        AppRoutes.attendance,
      ),
    ],
    UserRole.coordinator => const [
      ShellDestination(
        'Placements',
        Icons.assignment_outlined,
        Icons.assignment,
        AppRoutes.coordinatorDashboard,
      ),
      ShellDestination(
        'Students',
        Icons.school_outlined,
        Icons.school,
        AppRoutes.students,
      ),
      ShellDestination(
        'Lecturers',
        Icons.badge_outlined,
        Icons.badge,
        AppRoutes.lecturers,
      ),
      ShellDestination(
        'Reports',
        Icons.insights_outlined,
        Icons.insights,
        AppRoutes.reports,
      ),
    ],
    null => const [],
  };

  /// Index of the section a path belongs to, matching detail pages to
  /// their parent (`/coordinator/students/abc` → Students), or -1.
  static int indexFor(List<ShellDestination> destinations, String path) {
    var best = -1;
    var bestLength = 0;
    for (var i = 0; i < destinations.length; i++) {
      final route = destinations[i].route;
      final matches = path == route || path.startsWith('$route/');
      if (matches && route.length > bestLength) {
        best = i;
        bestLength = route.length;
      }
    }
    return best;
  }
}

/// The frame around every signed-in screen.
///
/// From [wideBreakpoint] up it's a sidebar with a top bar (the laptop
/// layout coordinators mostly use); below, an app bar with a bottom
/// navigation bar. Detail pages pass [showBack] and drop the bottom bar.
class AppShell extends ConsumerWidget {
  /// Creates the app shell.
  const AppShell({
    required this.role,
    required this.currentPath,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
    this.actions = const [],
    super.key,
  });

  /// Signed-in user's role; picks the navigation sections.
  final UserRole? role;

  /// Current route path, used to highlight the active section.
  final String currentPath;

  /// Page title.
  final String title;

  /// Optional line under the title on wide screens.
  final String? subtitle;

  /// Page content.
  final Widget child;

  /// Show a back button instead of the bottom navigation.
  final bool showBack;

  /// Extra top-bar actions for this page.
  final List<Widget> actions;

  /// Width from which the sidebar layout is used.
  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ShellDestination.forRole(role);
    final selected = ShellDestination.indexFor(destinations, currentPath);
    // The audit trail is a coordinator's fifth destination, but it's a
    // reference they dip into rather than a section they work in, so it
    // sits beside the bell instead of in the navigation.
    final shellActions = [
      if (role == UserRole.coordinator && currentPath != AppRoutes.audit)
        IconButton(
          tooltip: 'Audit history',
          onPressed: () => context.pushUnlessCurrent(AppRoutes.audit),
          icon: const Icon(Icons.history_rounded),
        ),
      ...actions,
    ];

    ref.listen(authenticationControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    // Offers a newer build once per launch; does nothing on iOS, on the
    // web, or in a Play build. See docs/APP_UPDATES.md.
    final content = UpdatePrompt(child: child);

    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              destinations: destinations,
              selected: selected,
              onSelect: (index) => _go(context, destinations[index].route),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: title,
                    subtitle: subtitle,
                    showBack: showBack,
                    onBack: () => _back(context),
                    actions: shellActions,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _back(context),
              )
            : Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Center(child: BrandMark(size: 30)),
              ),
        titleSpacing: showBack ? 0 : AppSpacing.xs,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          ...shellActions,
          const NotificationsBellButton(),
          const _AccountButton(compact: true),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: content,
      bottomNavigationBar: showBack || destinations.isEmpty
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: NavigationBar(
                selectedIndex: selected < 0 ? 0 : selected,
                onDestinationSelected: (index) =>
                    _go(context, destinations[index].route),
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            ),
    );
  }

  void _go(BuildContext context, String route) {
    if (route != currentPath) {
      context.go(route);
    }
  }

  /// Pops when there's somewhere to go back to; after a browser refresh
  /// there isn't, so fall back to the role's home instead of doing nothing.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AuthRedirects.dashboardForRole(role) ?? AppRoutes.splash);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<ShellDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLockup(markSize: 32),
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              _SidebarItem(
                destination: destinations[i],
                isSelected: i == selected,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: _AccountButton(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.blush : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.control),
          hoverColor: AppColors.mist,
          child: Semantics(
            selected: isSelected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color: isSelected ? AppColors.ink : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.ink
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      left: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
        child: Row(
          children: [
            if (showBack) ...[
              IconButton.outlined(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.line),
                  backgroundColor: AppColors.surface,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: textTheme.bodySmall),
                ],
              ),
            ),
            ...actions,
            const SizedBox(width: 4),
            const NotificationsBellButton(),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// The signed-in person, with a menu for their profile and signing out.
class _AccountButton extends ConsumerWidget {
  const _AccountButton({required this.compact});

  /// Avatar only (app bar) rather than avatar, name, and role (sidebar).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(profileControllerProvider)) {
      AsyncData(:final value) => value.user,
      _ => null,
    };
    final name = user == null ? '' : '${user.firstName} ${user.lastName}';
    final role = switch (user?.role) {
      UserRole.student => 'Student',
      UserRole.lecturer => 'Lecturer',
      UserRole.coordinator => 'Coordinator',
      null => '',
    };
    final textTheme = Theme.of(context).textTheme;
    final isSigningOut = ref.watch(authenticationControllerProvider).isLoading;

    // A popup menu item cannot show its own progress: the menu closes the
    // moment it is tapped. So the avatar becomes the spinner, and the menu
    // stops opening until sign-out finishes.
    if (isSigningOut) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      offset: Offset(0, compact ? 4 : -8),
      onSelected: (action) => switch (action) {
        _AccountAction.profile => context.pushUnlessCurrent(AppRoutes.profile),
        _AccountAction.signOut =>
          ref.read(authenticationControllerProvider.notifier).logout(),
      },
      itemBuilder: (context) => [
        if (name.isNotEmpty)
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleSmall),
                Text(user?.email ?? '', style: textTheme.bodySmall),
              ],
            ),
          ),
        const PopupMenuItem(
          value: _AccountAction.profile,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Profile & settings'),
          ),
        ),
        const PopupMenuItem(
          value: _AccountAction.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Sign out'),
          ),
        ),
      ],
      child: compact
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: AppAvatar(
                name: name.isEmpty ? '?' : name,
                photoUrl: user?.profilePhotoUrl,
                size: 32,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  AppAvatar(
                    name: name.isEmpty ? '?' : name,
                    photoUrl: user?.profilePhotoUrl,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                        Text(role, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 18),
                ],
              ),
            ),
    );
  }
}

enum _AccountAction { profile, signOut }
