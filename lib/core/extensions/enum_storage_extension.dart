/// Converts Dart enum names to Firestore snake_case values.
extension EnumStorageExtension on Enum {
  /// Returns the enum value in snake_case for Firestore storage.
  String get storageValue {
    return name.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
