import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistInitial());

  Map<String, int> _wishlistItems = {};

  void addToWishlist(ProductEntity product) {
    if (_wishlistItems.containsKey(product.id)) {
      _wishlistItems[product.id] = (_wishlistItems[product.id] ?? 0) + 1;
    } else {
      _wishlistItems[product.id] = 1;
    }
    emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
  }

  void removeFromWishlist(String productId) {
    _wishlistItems.remove(productId);
    emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromWishlist(productId);
    } else {
      _wishlistItems[productId] = quantity;
      emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
    }
  }

  void incrementQuantity(String productId) {
    _wishlistItems[productId] = (_wishlistItems[productId] ?? 0) + 1;
    emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
  }

  void decrementQuantity(String productId) {
    if (_wishlistItems.containsKey(productId)) {
      if (_wishlistItems[productId]! > 1) {
        _wishlistItems[productId] = _wishlistItems[productId]! - 1;
      } else {
        removeFromWishlist(productId);
        return;
      }
      emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
    }
  }

  void toggleWishlist(ProductEntity product) {
    if (_wishlistItems.containsKey(product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  bool isWishlisted(String productId) {
    return _wishlistItems.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _wishlistItems[productId] ?? 0;
  }

  void loadWishlist() {
    // For now, just emit loaded state with current items
    emit(WishlistLoaded(wishlistItems: Map.from(_wishlistItems)));
  }

  void clearWishlist() {
    _wishlistItems.clear();
    emit(const WishlistLoaded(wishlistItems: {}));
  }

  // Getters
  Map<String, int> get wishlistItems => Map.from(_wishlistItems);
  int get wishlistCount => _wishlistItems.values.fold(0, (sum, quantity) => sum + quantity);
}
