# Admin/Vendor App FCM Notification Implementation Guide

This guide provides a complete, step-by-step implementation for the Admin/Vendor App to handle FCM push notifications correctly according to your business requirements.

## Business Requirements Recap
- **Admin**: Receives push notifications for ALL new orders, regardless of vendor.
- **Vendor**: Receives push notifications ONLY for new orders that contain their products.

## Implementation Steps

### 1. Add Required Dependencies
Ensure these dependencies are in your `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^latest_version
  firebase_messaging: ^latest_version
  flutter_local_notifications: ^latest_version
  permission_handler: ^latest_version
  cloud_firestore: ^latest_version
  firebase_auth: ^latest_version
```

### 2. Create Notification Service
Create `lib/core/services/notification_service.dart`:

```dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_token_service.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Notification stream controllers
  static final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get messageStream =>
      _messageStreamController.stream;

  // Notification click stream
  static final StreamController<String?> _notificationClickStreamController =
      StreamController<String?>.broadcast();
  static Stream<String?> get notificationClickStream =>
      _notificationClickStreamController.stream;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get initial message if app was opened from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle messages when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Handle background messages (requires top-level function)
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Listen for token refresh
      _tokenRefreshSubscription =
          _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        // Update token in UserTokenService
        await UserTokenService().updateToken();
      });

      // Get and store FCM token
      await _getAndStoreToken();

      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Get and store FCM token
  Future<void> _getAndStoreToken() async {
    final token = await getFCMToken();
    if (token != null) {
      debugPrint('FCM Token obtained: $token');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    _showLocalNotification(message);

    // Add to stream for UI updates
    _messageStreamController.add(message);
  }

  /// Handle messages (background and terminated state)
  void _handleMessage(RemoteMessage message) {
    debugPrint('Received message: ${message.messageId}');

    // Add to stream for UI updates
    _messageStreamController.add(message);

    // Handle notification click
    if (message.data.isNotEmpty) {
      _notificationClickStreamController.add(message.data['orderId']);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'freshveggie_channel',
      'FreshVeggie Notifications',
      channelDescription: 'Notifications for order updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'FreshVeggie',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: message.data['orderId'],
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    _notificationClickStreamController.add(notificationResponse.payload);
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
    _notificationClickStreamController.close();
  }
}

/// Top-level function required for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // Add to stream for when app comes to foreground
  NotificationService._messageStreamController.add(message);
}
```

### 3. Create User Token Service
Create `lib/core/services/user_token_service.dart`:

```dart
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
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
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

      // Update tokens array (add new token if not present)
      final updatedTokens = <String>{
        ...?existingTokens,
        fcmToken,
      }.toList();

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
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final tokensData = userDoc.data()?['fcmTokens'];
          if (tokensData is List) {
            final existingTokens = tokensData.map((e) => e.toString()).toList();
            final updatedTokens = existingTokens.where((t) => t != fcmToken).toList();
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
```

### 4. Update Auth Cubit
Integrate token saving/removal in your auth cubit (e.g., `lib/features/auth/presentation/cubits/auth_cubit.dart`):

```dart
// Add this import
import '../../../../core/services/user_token_service.dart';

// In your _emitAuthenticated method, after determining role and vendorId:
await UserTokenService().saveTokenForUser(
  userRole: role,
  vendorId: vendorId,
);

// In your signOut method, before signing out:
await UserTokenService().removeTokenForUser();
```

### 5. Initialize Services in App
Initialize the NotificationService in your `lib/app.dart` or main initialization:

```dart
// Call this when your app starts
await NotificationService().initialize();
```

### 6. Android Setup (if not already done)
Update `android/app/build.gradle`:
```gradle
defaultConfig {
    // ...
    multiDexEnabled true
}

dependencies {
    // ...
    implementation 'com.android.support:multidex:1.0.3'
}
```

Update `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="freshveggie_channel" />
```

### 7. iOS Setup (if not already done)
Add these capabilities in `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## Key Features Implemented
- ✅ Role-based notification routing (Admin gets all, Vendor only their orders)
- ✅ Multi-device support (tokens stored as array)
- ✅ Token refresh handling
- ✅ Invalid token cleanup (handled by Cloud Functions)
- ✅ Foreground, background, and terminated state handling
- ✅ Local notifications for foreground messages
- ✅ Notification click handling

## Cloud Functions
Ensure the Cloud Functions from the User App are deployed (they handle sending notifications to the correct recipients).
