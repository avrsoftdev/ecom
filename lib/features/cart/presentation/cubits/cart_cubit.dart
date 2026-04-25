import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/entities/product_pricing.dart';
import '../../../product/domain/entities/product_unit_type.dart';
import '../../domain/entities/cart_item_entity.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({
    required SharedPreferences sharedPreferences,
  })  : _sharedPreferences = sharedPreferences,
        super(CartInitial());

  static const String _cartStorageKey = 'cart_items';

  final SharedPreferences _sharedPreferences;

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
    _persistCart();
  }

  void removeFromCart(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    _emitLoadedState();
    _persistCart();
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      _emitLoadedState();
      _persistCart();
    }
  }

  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
      addedAt: DateTime.now(),
    );
    _emitLoadedState();
    _persistCart();
  }

  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;

    final currentItem = _items[index];
    if (currentItem.quantity <= 1) {
      removeFromCart(cartItemId);
      return;
    }

    _items[index] = currentItem.copyWith(
      quantity: currentItem.quantity - 1,
      addedAt: DateTime.now(),
    );
    _emitLoadedState();
    _persistCart();
  }

  void clearCart() {
    _items.clear();
    emit(const CartLoaded(items: [], totalPrice: 0.0, totalItems: 0));
    _persistCart();
  }

  Future<void> loadCart() async {
    final raw = _sharedPreferences.getString(_cartStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = [];
      _emitLoadedState();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _items = [];
        _emitLoadedState();
        return;
      }

      _items = decoded
          .whereType<Map>()
          .map((entry) => _cartItemFromJson(Map<String, dynamic>.from(entry)))
          .toList();

      _emitLoadedState();
    } catch (_) {
      _items = [];
      _emitLoadedState();
    }
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

  CartItemEntity? preferredDisplayItemForProduct(String productId) {
    final matchingItems = _items
        .where((item) => item.product.id == productId)
        .toList(growable: false);

    if (matchingItems.isEmpty) {
      return null;
    }

    final tierItems = matchingItems
        .where((item) => item.isTierItem)
        .toList(growable: false);

    if (tierItems.isNotEmpty) {
      final sortedTierItems = [...tierItems]
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return sortedTierItems.first;
    }

    return matchingItems.first;
  }

  int quantityForProduct(String productId, {String? tierId}) => _items
      .where((item) => item.product.id == productId && item.tierId == tierId)
      .fold<int>(0, (sum, item) => sum + item.quantity);

  int totalQuantityForProduct(String productId) => _items
      .where((item) => item.product.id == productId)
      .fold<int>(0, (sum, item) => sum + item.quantity);
  
  double get cartTotal => _items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

  Future<void> _persistCart() async {
    final payload = _items.map(_cartItemToJson).toList();
    await _sharedPreferences.setString(_cartStorageKey, jsonEncode(payload));
  }

  Map<String, dynamic> _cartItemToJson(CartItemEntity item) {
    return {
      'id': item.id,
      'product': _productToJson(item.product),
      'quantity': item.quantity,
      'tierId': item.tierId,
      'tierLabel': item.tierLabel,
      'unitPrice': item.unitPrice,
      'addedAt': item.addedAt.toIso8601String(),
    };
  }

  CartItemEntity _cartItemFromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    return CartItemEntity(
      id: json['id'] as String? ?? '',
      product: _productFromJson(
        productJson is Map ? Map<String, dynamic>.from(productJson) : {},
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      tierId: json['tierId'] as String?,
      tierLabel: json['tierLabel'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      addedAt:
          DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _productToJson(ProductEntity product) {
    return {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'categoryId': product.categoryId,
      'stock': product.stock,
      'isAvailable': product.isAvailable,
      'createdAt': product.createdAt.toIso8601String(),
      'updatedAt': product.updatedAt.toIso8601String(),
      'discountPercent': product.discountPercent,
      'featured': product.featured,
      'imageUrls': product.imageUrls,
      'soldCount': product.soldCount,
      'unitType': product.unitType.code,
      'pricingTiers': product.pricingTiers.map((tier) => tier.toJson()).toList(),
    };
  }

  ProductEntity _productFromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      featured: json['featured'] as bool? ?? false,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      unitType: ProductUnitType.fromCode(
        json['unitType'] as String? ?? ProductUnitType.quantity.code,
      ),
      pricingTiers: (json['pricingTiers'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (tier) => ProductPricing.fromJson(
                  Map<String, dynamic>.from(tier),
                ),
              )
              .toList() ??
          const [],
    );
  }
}
