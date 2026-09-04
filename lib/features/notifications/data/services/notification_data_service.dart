import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for in-app notification documents.
///
/// Separate from `core/services/notification_service.dart`, which wraps the
/// FCM SDK for push delivery. This one only touches Firestore.
class NotificationDataService {
  /// Creates a notification data service.
  const NotificationDataService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Creates a new notification document ID.
  String createNotificationId() {
    return _firestore.collection('notifications').doc().id;
  }

  /// Returns a recipient's notifications, most recent first.
  Future<QuerySnapshot<Map<String, dynamic>>> getNotifications(
    String recipientId,
  ) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Marks every unread notification for a recipient as read, in one batch.
  Future<void> markAllAsRead(String recipientId) async {
    final unread = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
