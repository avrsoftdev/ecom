import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.shippingAddress,
    this.phone,
  });

  final String id;
  final String userId;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double deliveryCharge;
  final double tax;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? customerName;
  final String? customerEmail;
  final String? shippingAddress;
  final String? phone;

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        subtotal,
        deliveryCharge,
        tax,
        total,
        status,
        createdAt,
        updatedAt,
        customerName,
        customerEmail,
        shippingAddress,
        phone,
      ];
}
