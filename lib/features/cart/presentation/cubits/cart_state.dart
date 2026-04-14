part of 'cart_cubit.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemEntity> items;
  final double totalPrice;
  final int totalItems;

  const CartLoaded({
    required this.items,
    required this.totalPrice,
    required this.totalItems,
  });

  @override
  List<Object?> get props => [items, totalPrice, totalItems];

  CartLoaded copyWith({
    List<CartItemEntity>? items,
    double? totalPrice,
    int? totalItems,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

class CartError extends CartState {
  final String message;

  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}
