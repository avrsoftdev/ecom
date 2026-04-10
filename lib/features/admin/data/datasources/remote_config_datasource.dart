import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Reads Remote Config keys (values are managed in Firebase Console or Admin SDK).
class RemoteConfigDataSource {
  Future<void> ensureInitialized() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ),
    );
    await rc.setDefaults(const {'maintenance_mode': false});
    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // Offline / throttled — defaults apply.
    }
  }

  bool get maintenanceMode => FirebaseRemoteConfig.instance.getBool('maintenance_mode');
}
