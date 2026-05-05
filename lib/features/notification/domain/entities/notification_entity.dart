import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderDispatched,
  orderDelivered,
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final String? orderId;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.orderId,
    this.isRead = false,
  });

  factory NotificationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    String typeStr = data['type'] ?? 'orderDispatched';
    NotificationType type;
    switch (typeStr) {
      case 'orderDelivered':
        type = NotificationType.orderDelivered;
        break;
      case 'orderDispatched':
      default:
        type = NotificationType.orderDispatched;
        break;
    }

    DateTime timestamp;
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    return NotificationEntity(
      id: doc.id,
      title: data['title'] ?? 'Order Update',
      message: data['message'] ?? 'Your order has been updated',
      type: type,
      timestamp: timestamp,
      orderId: data['orderId'],
      isRead: data['isRead'] ?? false,
    );
  }

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    String? orderId,
    bool? isRead,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'orderId': orderId,
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        timestamp,
        orderId,
        isRead,
      ];
}
