import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';
import 'notifications_state.dart';

/// Controller for the signed-in user's notification list.
class NotificationsController extends AsyncNotifier<NotificationsState> {
  /// Loads the signed-in user's notifications.
  ///
  /// Watches the auth session so switching accounts reloads the correct
  /// user's notifications instead of serving whoever was signed in when
  /// this provider first built.
  @override
  Future<NotificationsState> build() async {
    final uid = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };
    return _load(uid);
  }

  /// Reloads the list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_currentUid()));
  }

  /// Marks one notification as read, updating the list in place.
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) {
      return;
    }
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const NotificationsState(),
    };

    final result = await ref
        .read(markNotificationReadUseCaseProvider)
        .one(notification.notificationId);

    switch (result) {
      case Success<void>():
        state = AsyncData(
          previous.copyWith(
            clearMessages: true,
            notifications: [
              for (final item in previous.notifications)
                if (item.notificationId == notification.notificationId)
                  item.copyWith(isRead: true)
                else
                  item,
            ],
          ),
        );
      case Failure<void>(:final error):
        state = AsyncData(
          previous.copyWith(clearMessages: true, errorMessage: error.message),
        );
    }
  }

  /// Marks every unread notification as read.
  Future<void> markAllAsRead() async {
    final uid = _currentUid();
    if (uid == null) {
      return;
    }
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const NotificationsState(),
    };

    final result = await ref.read(markNotificationReadUseCaseProvider).all(uid);

    switch (result) {
      case Success<void>():
        state = AsyncData(
          previous.copyWith(
            clearMessages: true,
            notifications: [
              for (final item in previous.notifications)
                item.copyWith(isRead: true),
            ],
          ),
        );
      case Failure<void>(:final error):
        state = AsyncData(
          previous.copyWith(clearMessages: true, errorMessage: error.message),
        );
    }
  }

  Future<NotificationsState> _load(String? uid) async {
    if (uid == null) {
      return const NotificationsState();
    }
    final result = await ref.read(getNotificationsUseCaseProvider).call(uid);
    return switch (result) {
      Success(:final data) => NotificationsState(notifications: data),
      Failure(:final error) => NotificationsState(errorMessage: error.message),
    };
  }

  String? _currentUid() {
    return switch (ref.read(authSessionProvider)) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };
  }
}
