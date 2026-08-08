/// Application-wide constants that are not feature-specific.
abstract final class AppConstants {
  /// Human-readable product name.
  static const appName = 'Servio';

  /// Recommended default page size for paginated Firestore reads.
  static const defaultPageSize = 20;

  /// Maximum file attachments per logbook entry documented by the DDS.
  static const maxAttachmentCount = 5;
}
