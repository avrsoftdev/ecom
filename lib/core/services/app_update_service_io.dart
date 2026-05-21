import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.localVersion,
    required this.storeVersion,
    required this.storeUrl,
  });

  final String localVersion;
  final String storeVersion;
  final String storeUrl;
}

class AppUpdateService {
  AppUpdateService({
    NewVersionPlus? versionChecker,
    String androidPackageId = _androidPackageId,
  })  : _versionChecker = versionChecker ??
            NewVersionPlus(
              androidId: androidPackageId,
            ),
        _androidPackageIdValue = androidPackageId;

  static const String _androidPackageId = 'com.bazariyo.avr';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_androidPackageId';

  final NewVersionPlus _versionChecker;
  final String _androidPackageIdValue;

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final status = await _versionChecker.getVersionStatus();
      if (status == null || !status.canUpdate) {
        return null;
      }

      return AppUpdateInfo(
        localVersion: status.localVersion,
        storeVersion: status.storeVersion,
        storeUrl: status.appStoreLink.isNotEmpty
            ? status.appStoreLink
            : _playStoreUrl,
      );
    } catch (error, stackTrace) {
      debugPrint('App update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> openPlayStore([String? storeUrl]) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    final urls = <Uri>[
      Uri.parse(storeUrl?.isNotEmpty == true ? storeUrl! : _playStoreUrl),
      Uri.parse('market://details?id=$_androidPackageIdValue'),
      Uri.parse(
        'https://play.google.com/store/apps/details?id=$_androidPackageIdValue',
      ),
    ];

    for (final url in urls) {
      try {
        final didLaunch = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (didLaunch) {
          return true;
        }
      } catch (error) {
        debugPrint('Failed to launch app update URL $url: $error');
      }
    }

    return false;
  }
}
