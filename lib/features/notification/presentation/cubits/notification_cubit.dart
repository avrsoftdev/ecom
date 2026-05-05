import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(NotificationInitial());

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  SharedPreferences? _prefs;
  
  static const String _readNotificationsKey = 'read_notifications';

  Future<void> loadNotifications() async {
    try {
      print('🔔 NotificationCubit: About to emit NotificationLoading state');
      emit(NotificationLoading());
      print('🔔 NotificationCubit: Emitted NotificationLoading state successfully');
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      print('🔔 NotificationCubit: SharedPreferences initialized');
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(const NotificationError('User not authenticated'));
        return;
      }

      print('Loading notifications for user: ${user.uid}');

      // Try to load from user notifications collection first
      try {
        print('Attempting to load from notifications collection...');
        _notificationsSubscription = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          print('Received notification snapshot: ${snapshot.docs.length} docs');
          _processNotificationSnapshot(snapshot);
        }, onError: (error) {
          print('Stream error: $error');
          if (error.toString().contains('PERMISSION_DENIED')) {
            print('Permissions denied for notifications collection stream, falling back to order data');
            _generateOrderNotifications();
          }
        });

        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .get();
        
        print('Got initial snapshot: ${snapshot.docs.length} docs');
        _processNotificationSnapshot(snapshot);
      } catch (e, stackTrace) {
        print('Error loading notifications collection: $e');
        print('Stack trace: $stackTrace');
        
        // If permissions error, fall back to order-based notifications
        if (e.toString().contains('PERMISSION_DENIED')) {
          print('Permissions denied for notifications collection, falling back to order data');
          await _generateOrderNotifications();
        } else {
          print('Unknown error, falling back to order data');
          await _generateOrderNotifications();
        }
      }
      
    } catch (e, stackTrace) {
      print('Critical error in loadNotifications: $e');
      print('Stack trace: $stackTrace');
      emit(NotificationError('Failed to load notifications: $e'));
    }
  }

  void _processNotificationSnapshot(QuerySnapshot snapshot) {
    try {
      final notifications = snapshot.docs
          .map((doc) => NotificationEntity.fromFirestore(doc))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));

      // Also generate notifications from order status changes
      _generateOrderNotifications();
    } catch (e) {
      emit(NotificationError('Failed to process notifications: $e'));
    }
  }

  Future<void> _generateOrderNotifications() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      print('Generating notifications from orders for user: ${user.uid}');
      
      // Get user's orders to generate notifications
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      print('Found ${ordersSnapshot.docs.length} orders');

      final notifications = <NotificationEntity>[];

      for (final orderDoc in ordersSnapshot.docs) {
        try {
          final orderData = orderDoc.data();
          final orderId = orderDoc.id;
          final status = orderData['status'] as String?;
          final createdAt = orderData['createdAt'] as Timestamp?;

          print('Processing order $orderId with status: $status');
          print('Order data keys: ${orderData.keys.toList()}');
          print('Full order data: $orderData');

          if (status != null && createdAt != null) {
            final normalizedStatus = status.toLowerCase().trim();
            print('🔍 Order $orderId normalized status: "$normalizedStatus"');
            
            // Generate notification based on order status (case-insensitive)
            if (normalizedStatus == 'dispatched') {
              final notificationId = '${orderId}_dispatched';
              final isRead = _isNotificationRead(notificationId);
              notifications.add(NotificationEntity(
                id: notificationId,
                title: 'Order Dispatched',
                message: 'Your order #$orderId has been dispatched and is on its way!',
                type: NotificationType.orderDispatched,
                timestamp: createdAt.toDate(),
                orderId: orderId,
                isRead: isRead,
              ));
              print('✅ Added dispatched notification for order $orderId (read: $isRead)');
            } else if (normalizedStatus == 'delivered') {
              final notificationId = '${orderId}_delivered';
              final isRead = _isNotificationRead(notificationId);
              notifications.add(NotificationEntity(
                id: notificationId,
                title: 'Order Delivered',
                message: 'Your order #$orderId has been successfully delivered. Enjoy your fresh vegetables!',
                type: NotificationType.orderDelivered,
                timestamp: createdAt.toDate(),
                orderId: orderId,
                isRead: isRead,
              ));
              print('✅ Added delivered notification for order $orderId (read: $isRead)');
            } else {
              print('❌ Order $orderId has status: "$status" (normalized: "$normalizedStatus")');
              print('   Expected statuses: "dispatched" or "delivered" (case-insensitive)');
            }
          } else {
            print('❌ Order $orderId missing required fields:');
            print('   Status: $status (${status.runtimeType})');
            print('   CreatedAt: $createdAt (${createdAt.runtimeType})');
          }
        } catch (e, stackTrace) {
          print('Error processing order ${orderDoc.id}: $e');
          print('Stack trace: $stackTrace');
          // Continue with next order
        }
      }

      // No sample notifications - only show real order notifications

      // Sort by timestamp
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final unreadCount = notifications.where((n) => !n.isRead).length;

      print('Generated ${notifications.length} notifications with $unreadCount unread');
      print('🔔 NotificationCubit: About to emit NotificationLoaded state');

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
      
      print('🔔 NotificationCubit: Emitted NotificationLoaded state successfully');

    } catch (e, stackTrace) {
      print('Error generating order notifications: $e');
      print('Stack trace: $stackTrace');
      
      // Emit empty state when there's an error - no sample notifications
      print('🔔 NotificationCubit: About to emit empty NotificationLoaded state due to error');
      emit(const NotificationLoaded(
        notifications: [],
        unreadCount: 0,
      ));
      print('🔔 NotificationCubit: Emitted empty NotificationLoaded state successfully');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    print('🔔 NotificationCubit: Marking notification as read: $notificationId');
    
    // Persist the read status
    await _markNotificationAsRead(notificationId);
    
    // Update local state
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      final updatedNotifications = currentState.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      print('🔔 NotificationCubit: Updated unread count to: $unreadCount');
      
      emit(NotificationLoaded(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));
    }
  }

  Future<void> markAllAsRead() async {
    print('🔔 NotificationCubit: Marking all notifications as read');
    
    // Since we're generating notifications from order data, handle this locally
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      final updatedNotifications = currentState.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      // Persist all notification IDs as read
      final notificationIds = updatedNotifications.map((n) => n.id).toList();
      await _markAllNotificationsAsRead(notificationIds);

      print('🔔 NotificationCubit: Marked all ${updatedNotifications.length} notifications as read');

      emit(NotificationLoaded(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    }
  }

  // Helper methods for persistence
  bool _isNotificationRead(String notificationId) {
    if (_prefs == null) return false;
    final readNotifications = _prefs!.getStringList(_readNotificationsKey) ?? [];
    return readNotifications.contains(notificationId);
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_prefs == null) return;
    final readNotifications = _prefs!.getStringList(_readNotificationsKey) ?? [];
    if (!readNotifications.contains(notificationId)) {
      readNotifications.add(notificationId);
      await _prefs!.setStringList(_readNotificationsKey, readNotifications);
      print('🔔 NotificationCubit: Persisted read notification: $notificationId');
    }
  }

  Future<void> _markAllNotificationsAsRead(List<String> notificationIds) async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_readNotificationsKey, notificationIds);
    print('🔔 NotificationCubit: Persisted all ${notificationIds.length} notifications as read');
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
