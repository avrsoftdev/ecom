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
  Future<AppUpdateInfo?> checkForUpdate() async {
    return null;
  }

  Future<bool> openPlayStore([String? storeUrl]) async {
    return false;
  }
}
