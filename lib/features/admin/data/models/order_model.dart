import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/domain/entities/order_entity.dart';
import 'order_item_model.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.subtotal,
    required super.deliveryCharge,
    required super.tax,
    required super.total,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.customerName,
    super.customerEmail,
    super.shippingAddress,
    super.phone,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return OrderModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (data['deliveryCharge'] as num?)?.toDouble() ?? 0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      createdAt: _ts(data['createdAt']) ?? DateTime.now(),
      updatedAt: _ts(data['updatedAt']),
      customerName: data['customerName'] as String?,
      customerEmail: data['customerEmail'] as String?,
      shippingAddress: data['shippingAddress'] as String?,
      phone: data['phone'] as String?,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items
          .map((e) => OrderItemModel(
                productId: e.productId,
                name: e.name,
                quantity: e.quantity,
                unitPrice: e.unitPrice,
                lineTotal: e.lineTotal,
                unitType: e.unitType,
              ).toJson())
          .toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'tax': tax,
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'customerName': customerName,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress,
      'phone': phone,
    };
  }

  OrderEntity toEntity() => this;
}
