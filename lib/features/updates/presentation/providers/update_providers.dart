import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/models/app_update_config.dart';
import '../../data/services/app_update_service.dart';
import '../../domain/update_decision.dart';

/// Provides the update service.
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(ref.watch(firebaseFirestoreProvider));
});

/// Whether this build is allowed to update itself at all.
///
/// Android-only: iOS permits installs through the App Store and TestFlight
/// alone, and the web updates itself on reload. Also off whenever
/// [AppConstants.selfUpdateEnabled] is false, which is how a Play build
/// opts out.
final selfUpdateSupportedProvider = Provider<bool>((ref) {
  if (!AppConstants.selfUpdateEnabled || kIsWeb) {
    return false;
  }
  return Platform.isAndroid;
});

/// Whether a newer build is published, and whether taking it is optional.
///
/// Checked once per app start. Resolves to [UpdateDecision.none] on any
/// failure: an update check that cannot complete must never stop someone
/// using the app.
final updateDecisionProvider = FutureProvider<UpdateDecision>((ref) async {
  if (!ref.watch(selfUpdateSupportedProvider)) {
    return UpdateDecision.none;
  }
  final service = ref.watch(appUpdateServiceProvider);
  try {
    final (installed, published) = await (
      service.installedBuildNumber(),
      service.publishedRelease(),
    ).wait;
    return UpdateDecision.from(
      installedBuildNumber: installed,
      config: published,
    );
  } catch (_) {
    return UpdateDecision.none;
  }
});

/// How a download is going: null until one starts, then a fraction, or
/// null fraction while the total size is unknown.
class UpdateDownload {
  /// Creates a download state.
  const UpdateDownload({this.progress, this.isRunning = false, this.error});

  /// Fraction complete, or null when the total size is unknown.
  final double? progress;

  /// Whether a download is in flight.
  final bool isRunning;

  /// Why the last attempt failed, if it did.
  final String? error;
}

/// Downloads a published build and hands it to the installer.
class UpdateDownloadController extends Notifier<UpdateDownload> {
  @override
  UpdateDownload build() => const UpdateDownload();

  /// Fetches [config]'s build, then opens the system installer.
  Future<void> start(AppUpdateConfig config) async {
    if (state.isRunning) {
      return;
    }
    state = const UpdateDownload(isRunning: true);
    try {
      final service = ref.read(appUpdateServiceProvider);
      final file = await service.download(
        config.downloadUrl,
        onProgress: (progress) {
          state = UpdateDownload(progress: progress, isRunning: true);
        },
      );
      await service.openForInstall(file);
      state = const UpdateDownload();
    } catch (error) {
      state = UpdateDownload(
        error:
            'The update couldn’t be downloaded. Check your connection and '
            'try again.',
      );
      debugPrint('Update download failed: $error');
    }
  }
}

/// Provides the download controller.
final updateDownloadControllerProvider =
    NotifierProvider<UpdateDownloadController, UpdateDownload>(
      UpdateDownloadController.new,
    );
