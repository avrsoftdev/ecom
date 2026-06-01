import '../../../common/domain/entities/order_item_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.productId,
    required super.vendorId,
    required super.name,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
    super.unitType,
    super.tierId,
    super.tierLabel,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      unitType: json['unitType'] as String?,
      tierId: json['tierId'] as String?,
      tierLabel: json['tierLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'vendorId': vendorId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
        'unitType': unitType,
        'tierId': tierId,
        'tierLabel': tierLabel,
      };
}
