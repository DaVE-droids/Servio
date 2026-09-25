import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_tone.dart';
import '../../../../core/enums/notification_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

/// The signed-in user's in-app notifications, newest first. Tapping one
/// marks it read and opens what it's about.
class NotificationsScreen extends ConsumerWidget {
  /// Creates the notifications screen.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsValue = ref.watch(notificationsControllerProvider);
    final role = ref.watch(authSessionProvider).value?.role;

    return notificationsValue.when(
      loading: () => const AppLoading(),
      error: (error, stackTrace) => AppErrorState(
        message:
            'Notifications couldn’t be loaded. Check your connection '
            'and try again.',
        onRetry: () =>
            ref.read(notificationsControllerProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.notifications.isEmpty) {
          return const AppEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications yet',
            message:
                'Decisions about placements, logbook reviews, and visit '
                'reports will show up here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.unreadCount == 0
                              ? 'You’re all caught up'
                              : '${state.unreadCount} unread',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (state.unreadCount > 0)
                        TextButton(
                          onPressed: () => ref
                              .read(notificationsControllerProvider.notifier)
                              .markAllAsRead(),
                          child: const Text('Mark all as read'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < state.notifications.length;
                          i++
                        ) ...[
                          if (i > 0) const Divider(indent: 68),
                          _NotificationRow(
                            notification: state.notifications[i],
                            onTap: () => _open(
                              context,
                              ref,
                              state.notifications[i],
                              role,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    UserRole? role,
  ) {
    ref.read(notificationsControllerProvider.notifier).markAsRead(notification);
    final destination = _destinationFor(notification.type, role);
    if (destination != null) {
      context.go(destination);
    }
  }

  /// Where a notification leads, for the person who received it.
  static String? _destinationFor(NotificationType type, UserRole? role) {
    return switch ((type, role)) {
      (NotificationType.placement, UserRole.student) => AppRoutes.internship,
      (NotificationType.placement, UserRole.lecturer) =>
        AppRoutes.assignedStudents,
      (NotificationType.logbook, UserRole.student || UserRole.lecturer) =>
        AppRoutes.logbook,
      (NotificationType.attendance, UserRole.student || UserRole.lecturer) =>
        AppRoutes.attendance,
      (NotificationType.supervision, UserRole.student) => AppRoutes.internship,
      (_, UserRole.coordinator) => AppRoutes.coordinatorDashboard,
      _ => null,
    };
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;
    final (icon, tone) = switch (notification.type) {
      NotificationType.placement => (Icons.work_outline, AppTone.ink),
      NotificationType.attendance => (
        Icons.event_available_outlined,
        AppTone.sky,
      ),
      NotificationType.logbook => (Icons.menu_book_outlined, AppTone.blush),
      NotificationType.supervision => (
        Icons.person_pin_circle_outlined,
        AppTone.ink,
      ),
      NotificationType.system => (Icons.info_outline, AppTone.neutral),
      NotificationType.announcement => (
        Icons.campaign_outlined,
        AppTone.warning,
      ),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.surfaceSunken : null,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: tone.foreground),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        Formatters.relative(notification.createdAt),
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.message, style: textTheme.bodyMedium),
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.xs, top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.blushStrong,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
