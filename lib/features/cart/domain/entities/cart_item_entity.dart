import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

class CartItemEntity extends Equatable {
  final String id;
  final ProductEntity product;
  final int quantity;
  final DateTime addedAt;

  const CartItemEntity({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        addedAt,
      ];

  CartItemEntity copyWith({
    String? id,
    ProductEntity? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => product.price * quantity;
}
