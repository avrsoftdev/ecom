import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.productId,
    required this.vendorId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.unitType,
    this.tierId,
    this.tierLabel,
  });

  final String productId;
  final String vendorId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? unitType;
  final String? tierId;
  final String? tierLabel;

  @override
  List<Object?> get props => [
        productId,
        vendorId,
        name,
        quantity,
        unitPrice,
        lineTotal,
        unitType,
        tierId,
        tierLabel,
      ];
}
