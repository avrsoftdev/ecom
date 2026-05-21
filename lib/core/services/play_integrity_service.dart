import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../firebase_options.dart';

class PlayIntegrityService {
  static const MethodChannel _channel = MethodChannel('com.bazariyo.freshveggie/integrity');

  Future<String?> getIntegrityToken({String? nonce}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('Play Integrity is only available on Android');
      return null;
    }

    try {
      // The nonce should ideally be generated on the server and passed here
      // to prevent replay attacks.
      // If no nonce is provided, we use a default or empty string (though server-side generation is recommended)
      final String? token = await _channel.invokeMethod<String>('getIntegrityToken', {
        'nonce': nonce ?? '',
        'cloudProjectNumber': DefaultFirebaseOptions.android.messagingSenderId,
      });
      return token;
    } catch (e) {
      debugPrint('Error getting Play Integrity token via MethodChannel: $e');
      return null;
    }
  }
}
