import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Feature-level service for Firestore profile and profile-photo storage access.
class ProfileService {
  /// Creates a profile service.
  const ProfileService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Loads a user profile document by Firebase Authentication UID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Updates editable profile fields for a user.
  Future<void> updateProfile(String uid, Map<String, Object?> data) {
    return _firestore.collection('users').doc(uid).update(data);
  }

  /// Returns all users with the lecturer role.
  Future<QuerySnapshot<Map<String, dynamic>>> getLecturers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'lecturer')
        .get();
  }

  /// Returns all users with the student role (coordinator only — the
  /// `users` list rule grants listing to coordinators alone).
  Future<QuerySnapshot<Map<String, dynamic>>> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
  }

  /// Approves or deactivates an account, writing the audit event and any
  /// notification in the same batch so neither can exist without the
  /// change itself.
  Future<void> setUserActive({
    required String uid,
    required bool isActive,
    required Map<String, dynamic> auditEvent,
    Map<String, dynamic>? notification,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    });
    batch.set(
      _firestore
          .collection('audit_events')
          .doc(auditEvent['eventId'] as String),
      auditEvent,
    );
    if (notification != null) {
      batch.set(
        _firestore
            .collection('notifications')
            .doc(notification['notificationId'] as String),
        notification,
      );
    }
    return batch.commit();
  }

  /// Creates a new document ID in [collection] without writing anything.
  String newId(String collection) => _firestore.collection(collection).doc().id;

  /// Uploads profile photo bytes and returns a download URL.
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final reference = _storage.ref('profile_photos/$uid/avatar.jpg');
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }
}
