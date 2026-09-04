import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';
import '../models/notification_model.dart';
import '../services/notification_data_service.dart';

/// Repository for reading and updating a user's in-app notifications.
class NotificationRepository {
  /// Creates a notification repository.
  const NotificationRepository(this._service);

  final NotificationDataService _service;

  /// Retrieves a recipient's notifications, most recent first.
  Future<Result<List<NotificationModel>>> getNotifications(
    String recipientId,
  ) async {
    try {
      final snapshot = await _service.getNotifications(recipientId);
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
      return Success(notifications);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Marks one notification as read.
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  /// Marks every unread notification for a recipient as read.
  Future<Result<void>> markAllAsRead(String recipientId) async {
    try {
      await _service.markAllAsRead(recipientId);
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(_mapFirebaseException(error));
    } catch (error) {
      return Failure(_unknownFailure(error));
    }
  }

  AppFailure _mapFirebaseException(FirebaseException error) {
    final message = switch (error.code) {
      'permission-denied' =>
        'You do not have permission to perform this action.',
      'unavailable' =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to load your notifications. Please try again.',
    };
    return AppFailure(
      message: message,
      type: error.code == 'unavailable'
          ? FailureType.network
          : FailureType.database,
      code: error.code,
      technicalDetails: error,
    );
  }

  AppFailure _unknownFailure(Object error) {
    return AppFailure(
      message: 'Something unexpected happened. Please try again.',
      technicalDetails: error,
    );
  }
}
