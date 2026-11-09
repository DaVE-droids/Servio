import 'package:flutter_test/flutter_test.dart';
import 'package:servio/features/updates/data/models/app_update_config.dart';
import 'package:servio/features/updates/domain/update_decision.dart';

void main() {
  AppUpdateConfig config({
    int latest = 5,
    int minimum = 2,
    String url = 'https://github.com/x/y/releases/download/v1/app.apk',
    String name = '1.1.0',
  }) {
    return AppUpdateConfig(
      latestBuildNumber: latest,
      latestVersionName: name,
      downloadUrl: url,
      releaseNotes: 'Fixed things',
      minimumBuildNumber: minimum,
    );
  }

  UpdateAction actionFor(int installed, {AppUpdateConfig? from}) {
    return UpdateDecision.from(
      installedBuildNumber: installed,
      config: from ?? config(),
    ).action;
  }

  group('UpdateDecision', () {
    test('offers an update when a newer build is published', () {
      expect(actionFor(4), UpdateAction.optional);
    });

    test('says nothing when the running build is the published one', () {
      expect(actionFor(5), UpdateAction.none);
    });

    test('says nothing when the running build is somehow newer', () {
      // A tester running a local build that was never published should not
      // be told to downgrade.
      expect(actionFor(9), UpdateAction.none);
    });

    test('requires the update below the minimum build', () {
      expect(actionFor(1), UpdateAction.required);
    });

    test('treats the minimum build itself as acceptable', () {
      expect(actionFor(2), UpdateAction.optional);
    });

    test('carries the release details when there is something to offer', () {
      final decision = UpdateDecision.from(
        installedBuildNumber: 4,
        config: config(),
      );
      expect(decision.config?.latestVersionName, '1.1.0');
    });

    group('refuses to act on an unusable document', () {
      test('missing entirely', () {
        expect(
          UpdateDecision.from(installedBuildNumber: 1, config: null).action,
          UpdateAction.none,
        );
      });

      test('a plain http download URL', () {
        // The file is about to be installed as software, so it may not come
        // over a connection that could be tampered with.
        expect(
          actionFor(1, from: config(url: 'http://example.com/app.apk')),
          UpdateAction.none,
        );
      });

      test('no version name to show', () {
        expect(actionFor(1, from: config(name: '')), UpdateAction.none);
      });

      test('no published build number', () {
        expect(actionFor(1, from: config(latest: 0)), UpdateAction.none);
      });
    });
  });

  group('AppUpdateConfig.fromJson', () {
    test('reads a well-formed document', () {
      final parsed = AppUpdateConfig.fromJson({
        'latestBuildNumber': 7,
        'latestVersionName': '1.2.0',
        'downloadUrl': 'https://example.com/app.apk',
        'releaseNotes': 'Notes',
        'minimumBuildNumber': 3,
      });
      expect(parsed.latestBuildNumber, 7);
      expect(parsed.minimumBuildNumber, 3);
      expect(parsed.isUsable, isTrue);
    });

    test('accepts a build number typed as a string in the console', () {
      final parsed = AppUpdateConfig.fromJson({
        'latestBuildNumber': ' 7 ',
        'latestVersionName': '1.2.0',
        'downloadUrl': 'https://example.com/app.apk',
      });
      expect(parsed.latestBuildNumber, 7);
    });

    test('survives an empty document instead of throwing', () {
      final parsed = AppUpdateConfig.fromJson({});
      expect(parsed.latestBuildNumber, 0);
      expect(parsed.isUsable, isFalse);
    });

    test('survives fields of the wrong type', () {
      final parsed = AppUpdateConfig.fromJson({
        'latestBuildNumber': 'not a number',
        'latestVersionName': '1.0.0',
        'downloadUrl': 'https://example.com/app.apk',
      });
      expect(parsed.latestBuildNumber, 0);
      expect(parsed.isUsable, isFalse);
    });
  });
}
