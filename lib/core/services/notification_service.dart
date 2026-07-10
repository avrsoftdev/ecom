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

    // Create notification channel explicitly for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'freshveggie_channel', // id
        'FreshVeggie Notifications', // name
        description: 'Notifications for order updates', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get FCM token and store it
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
      // Token will be stored when user logs in or creates order
      debugPrint('FCM Token obtained: $token');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages (since FCM won't show them automatically)
    _showLocalNotification(message);

    // Add to stream for UI updates
    _messageStreamController.add(message);
  }

  /// Handle messages (background and terminated state)
  void _handleMessage(RemoteMessage message) {
    debugPrint('Received message: ${message.messageId}');

    // Add to stream for UI updates
    _messageStreamController.add(message);

    // Handle notification tap
    if (message.data.isNotEmpty) {
      _notificationClickStreamController.add(message.data['orderId']);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // First, cancel any existing notifications with the same ID to avoid duplicates
    final notificationId = message.data['orderId']?.hashCode ??
        message.messageId?.hashCode ??
        message.hashCode;

    await _localNotifications.cancel(notificationId);

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
      notificationId,
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
