import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Service for managing user FCM tokens
class UserTokenService {
  static final UserTokenService _instance = UserTokenService._internal();
  factory UserTokenService() => _instance;
  UserTokenService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save FCM token to user profile when user logs in
  Future<void> saveTokenForUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = await NotificationService().getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      // Save token to user document
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeTokenForUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remove token from user document
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token removed for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Update FCM token (call when token changes)
  Future<void> updateToken() async {
    await saveTokenForUser();
  }
}
