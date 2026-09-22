import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_routes.dart';
import '../providers/notification_providers.dart';

/// App bar bell that opens the notifications list, with a badge showing how
/// many are unread.
///
/// Students reach notifications from their bottom navigation bar; lecturers
/// and coordinators have no such tab, so this is their way in.
class NotificationsBellButton extends ConsumerWidget {
  /// Creates the notifications bell button.
  const NotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = switch (ref.watch(notificationsControllerProvider)) {
      AsyncData(:final value) => value.unreadCount,
      _ => 0,
    };

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        await context.push(AppRoutes.notifications);
        // Coming back, re-read so the badge reflects anything marked read.
        ref.invalidate(notificationsControllerProvider);
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          unread > 0 ? Icons.notifications : Icons.notifications_none,
        ),
      ),
    );
  }
}
