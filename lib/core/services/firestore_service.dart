import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around Cloud Firestore SDK access.
class FirestoreService {
  /// Creates a Firestore service.
  const FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Returns a typed collection reference by path.
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Returns a write batch for atomic persistence workflows.
  WriteBatch batch() => _firestore.batch();
}
