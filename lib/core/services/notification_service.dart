import 'package:firebase_messaging/firebase_messaging.dart';

/// Thin wrapper around Firebase Cloud Messaging SDK access.
class NotificationService {
  /// Creates a notification service.
  const NotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  /// Returns the device push token when available.
  Future<String?> getToken() => _messaging.getToken();
}
