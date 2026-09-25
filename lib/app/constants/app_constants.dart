/// Application-wide constants that are not feature-specific.
abstract final class AppConstants {
  /// Human-readable product name.
  static const appName = 'Servio';

  /// Recommended default page size for paginated Firestore reads.
  static const defaultPageSize = 20;

  /// Maximum file attachments per logbook entry documented by the DDS.
  static const maxAttachmentCount = 5;

  /// Where the web app is hosted. The legal pages live here too, so the
  /// mobile apps link to the same copies the app stores are given.
  static const webBaseUrl = 'https://servio-e2974.web.app';

  /// Privacy policy (required by the App Store and Google Play).
  static const privacyPolicyUrl = '$webBaseUrl/privacy.html';

  /// Terms of use.
  static const termsUrl = '$webBaseUrl/terms.html';

  /// Whether people can upload a profile photo.
  ///
  /// Off while the Firebase project is on the free Spark plan: the project's
  /// Storage bucket (`*.firebasestorage.app`) refuses every upload without
  /// an active billing account (checked 2026-09-22), so the button would
  /// only ever show an error. Everyone gets an initials avatar meanwhile.
  /// After upgrading to Blaze, set this to true and follow
  /// docs/DEPLOYMENT.md ("After enabling Blaze").
  static const profilePhotoUploadsEnabled = false;
}
