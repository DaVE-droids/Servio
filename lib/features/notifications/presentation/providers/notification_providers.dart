import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_data_service.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../../domain/use_cases/mark_notification_read_use_case.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/notifications_state.dart';

/// Provides the notification Firestore service.
final notificationDataServiceProvider = Provider<NotificationDataService>((
  ref,
) {
  return NotificationDataService(ref.watch(firebaseFirestoreProvider));
});

/// Provides the notification repository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationDataServiceProvider));
});

/// Provides the get notifications use case.
final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((
  ref,
) {
  return GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

/// Provides the mark-notification-read use case.
final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
      return MarkNotificationReadUseCase(
        ref.watch(notificationRepositoryProvider),
      );
    });

/// Provides the notifications controller.
final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
