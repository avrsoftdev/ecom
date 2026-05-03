import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/notification_service.dart';

/// Widget that listens for notification taps and handles navigation
class PushNotificationListener extends StatefulWidget {
  final Widget child;

  const PushNotificationListener({
    super.key,
    required this.child,
  });

  @override
  State<PushNotificationListener> createState() => _PushNotificationListenerState();
}

class _PushNotificationListenerState extends State<PushNotificationListener> {
  late StreamSubscription<String?> _notificationClickSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationClickSubscription = NotificationService.notificationClickStream.listen(
      (orderId) {
        if (orderId != null && orderId.isNotEmpty && mounted) {
          // Navigate to order details page when notification is tapped
          context.go('/orders/$orderId');
        }
      },
      onError: (error) {
        debugPrint('Error in notification stream: $error');
      },
    );
  }

  @override
  void dispose() {
    _notificationClickSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
