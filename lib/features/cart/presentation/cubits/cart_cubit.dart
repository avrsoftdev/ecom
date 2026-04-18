import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  List<CartItemEntity> _items = [];

  void addToCart(
    ProductEntity product, {
    String? tierId,
    String? tierLabel,
    double? tierPrice,
  }) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.tierId == tierId,
    );

    if (existingItemIndex != -1) {
      // Update quantity if item already exists
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + 1,
      );
    } else {
      final unitPrice = tierPrice ?? product.effectivePrice;

      // Add new item
      final newItem = CartItemEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: 1,
        tierId: tierId,
        tierLabel: tierLabel,
        unitPrice: unitPrice,
        addedAt: DateTime.now(),
      );
      _items.add(newItem);
    }

    _emitLoadedState();
  }

  void removeFromCart(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    _emitLoadedState();
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      _emitLoadedState();
    }
  }

  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
    );
    _emitLoadedState();
  }

  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    final currentItem = _items[index];
    if (currentItem.quantity <= 1) {
      removeFromCart(cartItemId);
      return;
    }

    _items[index] = currentItem.copyWith(quantity: currentItem.quantity - 1);
    _emitLoadedState();
  }

  void clearCart() {
    _items.clear();
    emit(const CartLoaded(items: [], totalPrice: 0.0, totalItems: 0));
  }

  void loadCart() {
    // For now, just emit loaded state with current items
    _emitLoadedState();
  }

  void _emitLoadedState() {
    final totalPrice = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalItems = _items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    emit(CartLoaded(
      items: List.from(_items),
      totalPrice: totalPrice,
      totalItems: totalItems,
    ));
  }

  // Getters
  List<CartItemEntity> get items => List.from(_items);
  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);
  CartItemEntity? baseItemForProduct(String productId, {String? tierId}) {
    for (final item in _items) {
      if (item.product.id == productId && item.tierId == tierId) {
        return item;
      }
    }
    return null;
  }

  int quantityForProduct(String productId, {String? tierId}) => _items
      .where((item) => item.product.id == productId && item.tierId == tierId)
      .fold<int>(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
}
