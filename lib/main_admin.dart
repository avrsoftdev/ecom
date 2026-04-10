import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: kIsWeb ? const FreshVeggieAdminApp() : const _AdminWebOnlyApp(),
    ),
  );
}

Future<FirebaseApp> _initializeFirebase() {
  if (Firebase.apps.isNotEmpty) {
    return Future.value(Firebase.app());
  }

  if (kIsWeb) {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  return Firebase.initializeApp();
}

class _AdminWebOnlyApp extends StatelessWidget {
  const _AdminWebOnlyApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Admin panel is available on Web only.'),
        ),
      ),
    );
  }
}
