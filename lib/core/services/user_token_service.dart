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
  Future<void> saveTokenForUser({String? userRole, String? vendorId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = await NotificationService().getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      // Get existing user data to retrieve role and vendorId if not provided
      String? existingRole;
      String? existingVendorId;
      List<String>? existingTokens;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          existingRole = userDoc.data()?['role'] as String?;
          existingVendorId = userDoc.data()?['vendorId'] as String?;
          final tokensData = userDoc.data()?['fcmTokens'];
          if (tokensData is List) {
            existingTokens = tokensData.map((e) => e.toString()).toList();
          }
        }
      } catch (e) {
        debugPrint('Error fetching existing user data: $e');
      }

      // Use provided values or fall back to existing ones
      final role = userRole ?? existingRole ?? 'customer';
      final vid = vendorId ?? existingVendorId;

      // Update tokens array: add new token, remove duplicates, limit to last 5
      final tokenSet = <String>{
        fcmToken,
        ...?existingTokens,
      };
      final updatedTokens =
          tokenSet.take(5).toList(); // Keep only last 5 tokens

      // Save token to user document with role information
      final data = <String, dynamic>{
        'fcmTokens': updatedTokens,
        'role': role,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      // Add vendorId if user is a vendor
      if (role == 'vendor' && vid != null && vid.isNotEmpty) {
        data['vendorId'] = vid;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      debugPrint(
          'FCM token saved for user: ${user.uid} with role: $role. Total tokens: ${updatedTokens.length}');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeTokenForUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = await NotificationService().getFCMToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Remove specific token from array
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final tokensData = userDoc.data()?['fcmTokens'];
          if (tokensData is List) {
            final existingTokens = tokensData.map((e) => e.toString()).toList();
            final updatedTokens =
                existingTokens.where((t) => t != fcmToken).toList();
            await _firestore.collection('users').doc(user.uid).update({
              'fcmTokens': updatedTokens,
              'tokenUpdatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      debugPrint('FCM token removed for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Update FCM token (call when token changes)
  Future<void> updateToken({String? userRole, String? vendorId}) async {
    await saveTokenForUser(userRole: userRole, vendorId: vendorId);
  }
}
