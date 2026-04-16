part of 'wishlist_cubit.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final Map<String, int> wishlistItems;

  const WishlistLoaded({required this.wishlistItems});

  @override
  List<Object?> get props => [wishlistItems];

  WishlistLoaded copyWith({
    Map<String, int>? wishlistItems,
  }) {
    return WishlistLoaded(
      wishlistItems: wishlistItems ?? this.wishlistItems,
    );
  }
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError({required this.message});

  @override
  List<Object?> get props => [message];
}
