import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_data_service.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../controllers/notifications_controller.dart';

/// Provides the notification data service placeholder.
final notificationDataServiceProvider = Provider<NotificationDataService>((
  ref,
) {
  return const NotificationDataService();
});

/// Provides the notification repository placeholder.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return const NotificationRepository();
});

/// Provides the get notifications use case placeholder.
final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((
  ref,
) {
  return GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

/// Provides the notifications controller placeholder.
final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, void>(
      NotificationsController.new,
    );
