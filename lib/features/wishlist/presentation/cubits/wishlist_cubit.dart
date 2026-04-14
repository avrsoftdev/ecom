import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistInitial());

  List<ProductEntity> _wishlistItems = [];

  void addToWishlist(ProductEntity product) {
    if (!_wishlistItems.any((item) => item.id == product.id)) {
      _wishlistItems.add(product);
      emit(WishlistLoaded(wishlistItems: List.from(_wishlistItems)));
    }
  }

  void removeFromWishlist(String productId) {
    _wishlistItems.removeWhere((item) => item.id == productId);
    emit(WishlistLoaded(wishlistItems: List.from(_wishlistItems)));
  }

  void toggleWishlist(ProductEntity product) {
    if (_wishlistItems.any((item) => item.id == product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  bool isWishlisted(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  void loadWishlist() {
    // For now, just emit loaded state with current items
    emit(WishlistLoaded(wishlistItems: List.from(_wishlistItems)));
  }

  void clearWishlist() {
    _wishlistItems.clear();
    emit(const WishlistLoaded(wishlistItems: []));
  }

  // Getters
  List<ProductEntity> get wishlistItems => List.from(_wishlistItems);
  int get wishlistCount => _wishlistItems.length;
}
