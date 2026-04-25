import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/entities/product_pricing.dart';
import '../../../product/domain/entities/product_unit_type.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit({
    required SharedPreferences sharedPreferences,
  })  : _sharedPreferences = sharedPreferences,
        super(
          const WishlistLoaded(
            wishlistProducts: {},
            wishlistQuantities: {},
          ),
        );

  static const String _wishlistStorageKey = 'wishlist_items';

  final SharedPreferences _sharedPreferences;

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
    _persistWishlist();
  }

  void removeFromWishlist(String productId) {
    _wishlistProducts.remove(productId);
    _wishlistQuantities.remove(productId);
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
    _persistWishlist();
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
      _persistWishlist();
    }
  }

  void incrementQuantity(String productId) {
    _wishlistQuantities[productId] = (_wishlistQuantities[productId] ?? 0) + 1;
    emit(WishlistLoaded(
      wishlistProducts: Map.from(_wishlistProducts),
      wishlistQuantities: Map.from(_wishlistQuantities),
    ));
    _persistWishlist();
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
      _persistWishlist();
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

  Future<void> loadWishlist() async {
    final raw = _sharedPreferences.getString(_wishlistStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      emit(const WishlistLoaded(
        wishlistProducts: {},
        wishlistQuantities: {},
      ));
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        emit(const WishlistLoaded(
          wishlistProducts: {},
          wishlistQuantities: {},
        ));
        return;
      }

      final products = <String, ProductEntity>{};
      final quantities = <String, int>{};

      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }

        final entryMap = Map<String, dynamic>.from(entry);
        final productJson = entryMap['product'];
        if (productJson is! Map) {
          continue;
        }

        final product = _productFromJson(Map<String, dynamic>.from(productJson));
        products[product.id] = product;
        quantities[product.id] =
            (entryMap['quantity'] as num?)?.toInt() ?? 1;
      }

      _wishlistProducts = products;
      _wishlistQuantities = quantities;

      emit(WishlistLoaded(
        wishlistProducts: Map.from(_wishlistProducts),
        wishlistQuantities: Map.from(_wishlistQuantities),
      ));
    } catch (_) {
      _wishlistProducts = {};
      _wishlistQuantities = {};
      emit(const WishlistLoaded(
        wishlistProducts: {},
        wishlistQuantities: {},
      ));
    }
  }

  void clearWishlist() {
    _wishlistProducts.clear();
    _wishlistQuantities.clear();
    emit(const WishlistLoaded(
      wishlistProducts: {},
      wishlistQuantities: {},
    ));
    _persistWishlist();
  }

  // Getters
  Map<String, ProductEntity> get wishlistProducts => Map.from(_wishlistProducts);
  Map<String, int> get wishlistQuantities => Map.from(_wishlistQuantities);
  int get wishlistCount => _wishlistQuantities.values.fold(0, (sum, quantity) => sum + quantity);

  Future<void> _persistWishlist() async {
    final payload = _wishlistProducts.entries
        .map(
          (entry) => {
            'product': _productToJson(entry.value),
            'quantity': _wishlistQuantities[entry.key] ?? 1,
          },
        )
        .toList();

    await _sharedPreferences.setString(
      _wishlistStorageKey,
      jsonEncode(payload),
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
              .map((tier) => ProductPricing.fromJson(Map<String, dynamic>.from(tier)))
              .toList() ??
          const [],
    );
  }
}
