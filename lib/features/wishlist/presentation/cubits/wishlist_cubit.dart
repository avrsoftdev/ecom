import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistInitial());

  Map<String, ProductEntity> _wishlistProducts = {};
  Map<String, int> _wishlistQuantities = {};

  void addToWishlist(ProductEntity product) {
    if (_wishlistProducts.containsKey(product.id)) {
      _wishlistQuantities[product.id] = (_wishlistQuantities[product.id] ?? 0) + 1;
    } else {
      _wishlistProducts[product.id] = product;
      _wishlistQuantities[product.id] = 1;
    }
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
  }

  void removeFromWishlist(String productId) {
    _wishlistProducts.remove(productId);
    _wishlistQuantities.remove(productId);
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromWishlist(productId);
    } else {
      _wishlistQuantities[productId] = quantity;
      emit(WishlistLoaded(
        wishlistProducts: Map.from(_wishlistProducts),
        wishlistQuantities: Map.from(_wishlistQuantities),
      ));
    }
  }

  void incrementQuantity(String productId) {
    _wishlistQuantities[productId] = (_wishlistQuantities[productId] ?? 0) + 1;
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
  }

  void decrementQuantity(String productId) {
    if (_wishlistQuantities.containsKey(productId)) {
      if (_wishlistQuantities[productId]! > 1) {
        _wishlistQuantities[productId] = _wishlistQuantities[productId]! - 1;
      } else {
        removeFromWishlist(productId);
        return;
      }
      emit(WishlistLoaded(
        wishlistProducts: Map.from(_wishlistProducts),
        wishlistQuantities: Map.from(_wishlistQuantities),
      ));
    }
  }

  void toggleWishlist(ProductEntity product) {
    if (_wishlistProducts.containsKey(product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  bool isWishlisted(String productId) {
    return _wishlistProducts.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _wishlistQuantities[productId] ?? 0;
  }

  ProductEntity? getProduct(String productId) {
    return _wishlistProducts[productId];
  }

  void loadWishlist() {
    // For now, just emit loaded state with current items
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
  }

  void clearWishlist() {
    _wishlistProducts.clear();
    _wishlistQuantities.clear();
    emit(const WishlistLoaded(
      wishlistProducts: {},
      wishlistQuantities: {},
    ));
  }

  // Getters
  Map<String, ProductEntity> get wishlistProducts => Map.from(_wishlistProducts);
  Map<String, int> get wishlistQuantities => Map.from(_wishlistQuantities);
  int get wishlistCount => _wishlistQuantities.values.fold(0, (sum, quantity) => sum + quantity);
}
