import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class AppCheckService {
  AppCheckService._();

  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: kDebugMode
              ? WebDebugProvider()
              : ReCaptchaV3Provider('REPLACE_WITH_YOUR_RECAPTCHA_SITE_KEY'),
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? AndroidDebugProvider()
              : AndroidPlayIntegrityProvider(),
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? AppleDebugProvider()
              : AppleDeviceCheckProvider(),
        );
        return;
      }

      debugPrint('Firebase App Check is not initialized on this platform.');
    } catch (error, stack) {
      debugPrint('Firebase App Check initialization failed: $error');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
    }
  }
}
