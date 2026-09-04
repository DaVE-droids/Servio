import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/enums/notification_type.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

/// Lists the signed-in user's in-app notifications.
class NotificationsScreen extends ConsumerWidget {
  /// Creates the notifications screen.
  const NotificationsScreen({this.showScaffold = true, super.key});

  /// Whether to wrap the list in its own scaffold. Students reach this
  /// through the app shell, which supplies its own.
  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsValue = ref.watch(notificationsControllerProvider);

    final body = notificationsValue.when(
      loading: () => const AppLoading(message: 'Loading notifications...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load your notifications. Please try again.',
        onRetry: () =>
            ref.read(notificationsControllerProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.notifications.isEmpty) {
          return const AppEmptyState(
            title: 'No Notifications',
            message:
                'Updates about your placement, logbook, and supervision '
                'visits will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.notifications.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Header(unreadCount: state.unreadCount);
              }
              final notification = state.notifications[index - 1];
              return _NotificationCard(
                notification: notification,
                onTap: () => ref
                    .read(notificationsControllerProvider.notifier)
                    .markAsRead(notification),
              );
            },
          ),
        );
      },
    );

    if (!showScaffold) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              unreadCount == 0
                  ? 'All caught up'
                  : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(notification.type),
                size: 20,
                color: isUnread ? AppColors.primary : AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(notification.message, style: textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: AppSpacing.xs, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.placement => Icons.work_outline,
      NotificationType.attendance => Icons.fact_check_outlined,
      NotificationType.logbook => Icons.menu_book_outlined,
      NotificationType.supervision => Icons.person_search_outlined,
      NotificationType.system => Icons.info_outline,
      NotificationType.announcement => Icons.campaign_outlined,
    };
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date at $time';
}
