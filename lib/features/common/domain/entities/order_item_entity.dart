import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [productId, name, quantity, unitPrice, lineTotal];
}
