# Admin App FCM Notification Implementation Prompt

## Overview
Implement FCM push notifications in the admin app to receive alerts when users place new orders. The user app has been configured to create notification documents that the admin app should listen for and process.

## What's Already Implemented in User App

### 1. Notification Trigger System
- **AdminNotificationService** creates notification documents when orders are placed
- **Notification documents** are stored in `admin_notifications` collection
- **FCM tokens** are stored with user roles in `users` collection
- **Order data** includes customer information for notification content

### 2. Notification Document Structure
When a user places an order, the user app creates a document in `admin_notifications` collection:

```javascript
{
  type: 'new_order',
  orderId: 'order_id_here',
  customerName: 'Customer Name',
  customerEmail: 'customer@email.com',
  phone: '+1234567890',
  totalAmount: 299.99,
  title: 'New Order Received!',
  body: 'Order #12345 from Customer Name - Amount: ₹299.99',
  sound: 'alert_ring.mp3', // Custom alert sound
  priority: 'high',
  createdAt: timestamp,
  isRead: false,
  targetRole: 'admin'
}
```

### 3. Admin Token Management
- Admin users store FCM tokens in `users` collection with `role: 'admin'`
- User app automatically manages token storage for all user roles

## Required Admin App Implementation

### **1. Dependencies (pubspec.yaml)**
```yaml
dependencies:
  firebase_core: latest
  firebase_messaging: latest
  flutter_local_notifications: latest
  cloud_firestore: latest
```

### **2. FCM Initialization & Token Management**
```dart
// Initialize Firebase Messaging for admin app
class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  Future<void> initialize() async {
    // Request permissions
    await FirebaseMessaging.instance.requestPermission();
    
    // Get and store admin FCM token
    final token = await FirebaseMessaging.instance.getToken();
    await _saveAdminToken(token);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Listen for admin notifications from Firestore
    _listenForAdminNotifications();
  }
  
  Future<void> _saveAdminToken(String token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'fcmToken': token,
        'role': 'admin',
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
```

### **3. Cloud Function for Notification Processing**
Create a Firebase Cloud Function that listens to `admin_notifications` collection:

```javascript
// functions/index.js
exports.sendAdminNotification = functions.firestore
  .document('admin_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (notification.type === 'new_order' && notification.targetRole === 'admin') {
      // Get all admin FCM tokens
      const adminDocs = await admin.firestore()
        .collection('users')
        .where('role', '==', 'admin')
        .where('fcmToken', '!=', null)
        .get();
      
      const tokens = adminDocs.docs.map(doc => doc.data().fcmToken);
      
      // Send notification to all admins
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
          sound: notification.sound || 'default',
        },
        data: {
          type: 'new_order',
          orderId: notification.orderId,
          customerName: notification.customerName,
          totalAmount: notification.totalAmount.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
        android: {
          priority: 'high',
          notification: {
            sound: notification.sound || 'default',
            priority: 'high',
            defaultSound: false,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: notification.sound || 'default',
              priority: 'high',
            },
          },
        },
      };
      
      // Send the message
      await admin.messaging().sendMulticast(message);
      
      // Mark notification as processed
      await snap.ref.update({ processed: true, processedAt: FieldValue.serverTimestamp() });
    }
  });
```

### **4. Local Notification Handling**
```dart
class AdminNotificationHandler {
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification with custom sound
    FlutterLocalNotificationsPlugin().show(
      message.hashCode,
      message.notification?.title ?? 'New Order',
      message.notification?.body ?? 'You have a new order',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'admin_orders',
          'Admin Order Notifications',
          channelDescription: 'Notifications for new orders',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('alert_ring'),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'alert_ring.mp3',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['orderId'],
    );
  }
  
  void _handleMessage(RemoteMessage message) {
    // Navigate to order details when notification is tapped
    if (message.data['type'] == 'new_order') {
      Get.toNamed('/admin/orders/${message.data['orderId']}');
    }
  }
}
```

### **5. Custom Alert Sound Setup**
1. **Add sound file**: Place `alert_ring.mp3` in `android/app/src/main/res/raw/`
2. **iOS configuration**: Add sound to iOS bundle in `ios/Runner/`
3. **Channel configuration**: Configure notification channel with custom sound

### **6. Admin App Initialization**
```dart
// In main.dart or admin app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize admin notifications
  await AdminNotificationService().initialize();
  
  runApp(AdminApp());
}
```

### **7. Order Management Integration**
Update order management to show real-time notifications:
```dart
class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  StreamSubscription<QuerySnapshot>? _newOrdersSubscription;
  
  @override
  void initState() {
    super.initState();
    _listenForNewOrders();
  }
  
  void _listenForNewOrders() {
    _newOrdersSubscription = FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snapshot) {
        // Show badge or refresh UI when new orders arrive
        _updateOrderCount(snapshot.docs.length);
      });
  }
}
```

## Key Features to Implement

### **1. Alert Ring Sound**
- Use grocery delivery-style alert sound
- Sound plays for every new order
- High priority notifications

### **2. Real-time Updates**
- Listen to Firestore for new orders
- Show order count badges
- Auto-refresh order list

### **3. Navigation Handling**
- Tap notification → Navigate to order details
- Deep linking to specific orders
- Proper back navigation

### **4. Notification Management**
- Mark notifications as read
- Notification history
- Clear all notifications

## Testing Checklist

1. **FCM Token Storage**: Verify admin tokens are stored correctly
2. **Notification Trigger**: Test user order placement creates notification document
3. **Cloud Function**: Verify function processes notifications correctly
4. **Sound Playback**: Test custom alert sound plays
5. **Navigation**: Test notification tap navigates to order details
6. **Multiple Admins**: Test all admins receive notifications

## Expected User Experience

1. **User places order** → Notification document created
2. **Cloud Function triggers** → Sends FCM to all admins
3. **Admin receives notification** → Alert sound plays
4. **Admin taps notification** → Opens order details
5. **Admin processes order** → Status update triggers user notification

This implementation provides a complete grocery delivery-style notification system with alert sounds and real-time order management.
