import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

class CartItemEntity extends Equatable {
  final String id;
  final ProductEntity product;
  final int quantity;
  final String? tierId;
  final String? tierLabel;
  final double unitPrice;
  final DateTime addedAt;

  const CartItemEntity({
    required this.id,
    required this.product,
    required this.quantity,
    this.tierId,
    this.tierLabel,
    required this.unitPrice,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        tierId,
        tierLabel,
        unitPrice,
        addedAt,
      ];

  CartItemEntity copyWith({
    String? id,
    ProductEntity? product,
    int? quantity,
    String? tierId,
    String? tierLabel,
    double? unitPrice,
    DateTime? addedAt,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      tierId: tierId ?? this.tierId,
      tierLabel: tierLabel ?? this.tierLabel,
      unitPrice: unitPrice ?? this.unitPrice,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  bool get isTierItem => tierId != null;
  String get displayName =>
      tierLabel == null ? product.name : '${product.name} - $tierLabel';
  double get totalPrice => unitPrice * quantity;
}
