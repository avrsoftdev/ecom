import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for sending notifications to admin users when orders are placed
class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to all admin users when a new order is placed
  Future<void> notifyAdminsOnNewOrder({
    required String orderId,
    required String customerName,
    required double totalAmount,
    required String customerEmail,
    required String phone,
  }) async {
    try {
      // First, get all admin FCM tokens
      final adminTokens = await getAdminFCMTokens();
      debugPrint('Found ${adminTokens.length} admin tokens');

      if (adminTokens.isNotEmpty) {
        // Create direct notification document
        await createDirectAdminNotification(
          orderId: orderId,
          customerName: customerName,
          totalAmount: totalAmount,
          adminTokens: adminTokens,
        );
      }

      // Also create notification document for Cloud Function to process (as backup)
      await _firestore.collection('admin_notifications').add({
        'type': 'new_order',
        'orderId': orderId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'phone': phone,
        'totalAmount': totalAmount,
        'title': 'New Order Received!',
        'body': 'Order #$orderId from $customerName - Amount: ₹${totalAmount.toStringAsFixed(2)}',
        'sound': 'alert_ring.mp3', // Custom alert sound for grocery delivery feel
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'targetRole': 'admin', // Target all admin users
      });

      debugPrint('Admin notification created for new order: $orderId');
    } catch (e) {
      debugPrint('Error creating admin notification: $e');
    }
  }

  /// Get all admin FCM tokens for sending notifications
  Future<List<String>> getAdminFCMTokens() async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      final tokens = adminsSnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      return tokens;
    } catch (e) {
      debugPrint('Error getting admin FCM tokens: $e');
      return [];
    }
  }

  /// Create a direct notification document for immediate processing
  Future<void> createDirectAdminNotification({
    required String orderId,
    required String customerName,
    required double totalAmount,
    required List<String> adminTokens,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': '🛒 New Order Alert!',
        'body': 'Order #$orderId\nCustomer: $customerName\nAmount: ₹${totalAmount.toStringAsFixed(2)}',
        'tokens': adminTokens,
        'data': {
          'type': 'new_order',
          'orderId': orderId,
          'customerName': customerName,
          'totalAmount': totalAmount.toString(),
          'sound': 'alert_ring',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'sound': 'alert_ring',
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Direct admin notification created for order: $orderId');
    } catch (e) {
      debugPrint('Error creating direct admin notification: $e');
    }
  }
}
