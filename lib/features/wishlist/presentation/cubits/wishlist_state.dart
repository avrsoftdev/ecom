part of 'wishlist_cubit.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final Map<String, ProductEntity> wishlistProducts;
  final Map<String, int> wishlistQuantities;

  const WishlistLoaded({
    required this.wishlistProducts,
    required this.wishlistQuantities,
  });

  @override
  List<Object?> get props => [wishlistProducts, wishlistQuantities];

  WishlistLoaded copyWith({
    Map<String, ProductEntity>? wishlistProducts,
    Map<String, int>? wishlistQuantities,
  }) {
    return WishlistLoaded(
      wishlistProducts: wishlistProducts ?? this.wishlistProducts,
      wishlistQuantities: wishlistQuantities ?? this.wishlistQuantities,
    );
  }
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError({required this.message});

  @override
  List<Object?> get props => [message];
}
