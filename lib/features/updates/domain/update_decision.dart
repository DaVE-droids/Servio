import '../data/models/app_update_config.dart';

/// What to do about a newer build being available.
enum UpdateAction {
  /// The app is current, or there is nothing trustworthy to act on.
  none,

  /// A newer build exists; the user may take it or carry on.
  optional,

  /// The running build is too old to be relied on and must be replaced.
  required,
}

/// The outcome of comparing the running build against the published one.
class UpdateDecision {
  const UpdateDecision._(this.action, {this.config});

  /// Nothing to offer.
  static const UpdateDecision none = UpdateDecision._(UpdateAction.none);

  /// What to do.
  final UpdateAction action;

  /// The published release, when there is one to offer.
  final AppUpdateConfig? config;

  /// Compares the running [installedBuildNumber] against [config].
  ///
  /// Build numbers are compared as integers, never version names as text:
  /// as text, "1.10" sorts before "1.9", which would silently stop
  /// offering updates after the tenth release.
  ///
  /// Anything unusable — a missing or unparseable document, a download URL
  /// that is not https, a build number that is somehow behind the running
  /// one — resolves to [UpdateAction.none]. Being unable to check for an
  /// update is not a reason to interrupt someone's work.
  factory UpdateDecision.from({
    required int installedBuildNumber,
    required AppUpdateConfig? config,
  }) {
    if (config == null || !config.isUsable) {
      return none;
    }
    if (installedBuildNumber < config.minimumBuildNumber) {
      return UpdateDecision._(UpdateAction.required, config: config);
    }
    if (installedBuildNumber < config.latestBuildNumber) {
      return UpdateDecision._(UpdateAction.optional, config: config);
    }
    return none;
  }
}
