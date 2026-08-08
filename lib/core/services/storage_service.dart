import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Firebase Storage SDK access.
class StorageService {
  /// Creates a storage service.
  const StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Returns a storage reference for the provided path.
  Reference ref(String path) => _storage.ref(path);
}
