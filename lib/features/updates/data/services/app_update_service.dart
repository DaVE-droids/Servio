import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../models/app_update_config.dart';

/// Reads the published release details, downloads a build, and hands it to
/// the system installer.
class AppUpdateService {
  /// Creates an update service.
  const AppUpdateService(this._firestore);

  final FirebaseFirestore _firestore;

  /// The build number of the running app (`+N` in `pubspec.yaml`).
  Future<int> installedBuildNumber() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  /// Reads the published release details, or null if there are none to
  /// read.
  ///
  /// Never throws: being offline, or a document that was never created, is
  /// the normal state and must not interrupt anything.
  Future<AppUpdateConfig?> publishedRelease() async {
    try {
      final path = AppConstants.appUpdateConfigPath.split('/');
      final snapshot = await _firestore
          .collection(path.first)
          .doc(path.last)
          .get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return AppUpdateConfig.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Downloads [url] to the app's private storage, reporting progress
  /// between 0 and 1, and returns the finished file.
  ///
  /// Progress is reported only once the server states a content length;
  /// without one there is no total to measure against, and the caller shows
  /// an indeterminate bar instead.
  Future<File> download(
    String url, {
    required void Function(double? progress) onProgress,
  }) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }

      // The app's own cache directory: no storage permission is involved,
      // and Android reclaims it with the app. Written under a temporary
      // name and renamed on completion, so an interrupted download can
      // never be handed to the installer as if it were whole.
      final directory = await getApplicationCacheDirectory();
      final target = File('${directory.path}/servio-update.apk');
      final partial = File('${target.path}.part');
      if (await partial.exists()) {
        await partial.delete();
      }

      final total = response.contentLength;
      var received = 0;
      final sink = partial.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(total == null || total == 0 ? null : received / total);
        }
      } finally {
        await sink.close();
      }

      if (total != null && total > 0 && received != total) {
        await partial.delete();
        throw const HttpException('Download ended early');
      }

      if (await target.exists()) {
        await target.delete();
      }
      return await partial.rename(target.path);
    } finally {
      client.close();
    }
  }

  /// Hands a downloaded build to the system installer.
  ///
  /// Android shows its own install screen from here, and the final tap is
  /// always the user's — an app cannot install software silently.
  ///
  /// Implemented in `MainActivity.kt` rather than through a package: the
  /// published Flutter plugins for this pin an older Android Gradle Plugin
  /// and use DSL that AGP 9 removed, and this is the one call in Servio
  /// that installs software on a phone.
  Future<void> openForInstall(File file) {
    return _installer.invokeMethod<void>('install', {'path': file.path});
  }

  static const _installer = MethodChannel('servio/installer');
}
