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

  /// How far from the company address still counts as being at work when a
  /// student checks in.
  ///
  /// Generous on purpose: the address came from a geocoded search, so the
  /// pin can sit on the wrong side of a large site, and a phone indoors is
  /// often tens of metres out. The point is to tell "at the office" apart
  /// from "at home", not to measure which floor someone is on.
  static const attendanceGeofenceRadiusMetres = 250.0;

  /// Readings vaguer than this are treated as no reading at all, rather
  /// than being used to put a student inside or outside the fence.
  static const attendanceMaxLocationAccuracyMetres = 200.0;

  /// Whether the app checks for a newer build and offers to install it.
  ///
  /// On for the APKs handed to testers directly: without this they have no
  /// way of knowing an update exists. **Set it to false for any build
  /// uploaded to Google Play** — Play forbids an app it distributes from
  /// updating itself by any other route, and Play does the job itself
  /// anyway. See docs/APP_UPDATES.md §9.
  static const selfUpdateEnabled = true;

  /// The Firestore document holding the published release details.
  static const appUpdateConfigPath = 'app_config/android';
}
