/// The published-release note the app reads to find out whether it is
/// behind: one Firestore document at `app_config/android`, edited by hand
/// in the Firebase console after each release.
///
/// See `docs/APP_UPDATES.md` for the release routine.
class AppUpdateConfig {
  /// Creates an update config.
  const AppUpdateConfig({
    required this.latestBuildNumber,
    required this.latestVersionName,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.minimumBuildNumber,
  });

  /// The newest published build number (`+N` in `pubspec.yaml`).
  final int latestBuildNumber;

  /// The human-readable version name, shown in the dialog.
  final String latestVersionName;

  /// Where the APK can be downloaded from.
  final String downloadUrl;

  /// What changed, shown so the update is worth tapping.
  final String releaseNotes;

  /// Builds below this cannot be trusted and must update before going on.
  final int minimumBuildNumber;

  /// Whether this document says enough to act on.
  ///
  /// The URL must be https: the APK is about to be installed as software,
  /// so it may not be fetched over a connection anyone could tamper with.
  bool get isUsable {
    return latestBuildNumber > 0 &&
        downloadUrl.startsWith('https://') &&
        latestVersionName.isNotEmpty;
  }

  /// Reads a config document, tolerating missing and mistyped fields.
  ///
  /// Hand-edited in a console, so a number saved as a string or a field
  /// left out entirely is a question of when, not if. Anything unreadable
  /// becomes a value that makes [isUsable] false rather than an exception.
  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      latestBuildNumber: _readInt(json['latestBuildNumber']),
      latestVersionName: json['latestVersionName'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      minimumBuildNumber: _readInt(json['minimumBuildNumber']),
    );
  }

  static int _readInt(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text.trim()) ?? 0,
      _ => 0,
    };
  }
}
