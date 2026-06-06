import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/vendor_delivery_service.dart';
import '../../../common/domain/entities/banner_entity.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class HomeRemoteDataSource {
  Future<List<BannerEntity>> getBanners({
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<CategoryEntity>> getCategories({
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<ProductEntity>> getFeaturedProducts({
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<ProductEntity>> getNewArrivals({
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<ProductEntity>> getDeals({
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<ProductEntity>> getRecommendedProducts({
    double? userLatitude,
    double? userLongitude,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;
  VendorDeliveryService get _vendorService =>
      VendorDeliveryService(firestore: firestore);

  @override
  Future<List<BannerEntity>> getBanners({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final snapshot = await firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .get();

    final banners = snapshot.docs
        .map((doc) => _mapBanner(doc))
        .whereType<BannerEntity>()
        .toList();

    final filtered = await _filterByVendorServiceability(
      banners,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      getVendorId: (b) => b.vendorId,
    );

    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }

  @override
  Future<List<CategoryEntity>> getCategories({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final snapshot = await firestore.collection('categories').get();

    final categories = snapshot.docs
        .map((doc) => _mapCategory(doc))
        .whereType<CategoryEntity>()
        .toList();

    final filtered = await _filterByVendorServiceability(
      categories,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      getVendorId: (c) => c.vendorId,
    );

    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }

  Future<List<T>> _filterByVendorServiceability<T>(
    List<T> items, {
    double? userLatitude,
    double? userLongitude,
    required String? Function(T) getVendorId,
  }) async {
    if (userLatitude == null || userLongitude == null) {
      debugPrint('[DEBUG] Filtering skipped: User location missing');
      return items;
    }

    final vendorIds = items
        .map(getVendorId)
        .where((id) => id != null && id.trim().isNotEmpty)
        .cast<String>()
        .toSet();

    if (vendorIds.isEmpty) {
      debugPrint('[DEBUG] Filtering: No vendor-specific items found');
      return items;
    }

    final vendorMap = await _vendorService.loadVendorMetadata(vendorIds);

    return items.where((item) {
      final vendorId = getVendorId(item);
      if (vendorId == null || vendorId.trim().isEmpty) {
        return true; // Global items
      }

      final vendor = vendorMap[vendorId];
      if (vendor == null) {
        debugPrint('[DEBUG] Item filtered out: Vendor $vendorId not found');
        return false;
      }
      if (vendor.isBlocked) {
        debugPrint(
            '[DEBUG] Item filtered out: Vendor ${vendor.storeName} is blocked');
        return false;
      }
      if (vendor.latitude == null || vendor.longitude == null) {
        debugPrint(
            '[DEBUG] Item filtered out: Vendor ${vendor.storeName} missing location');
        return false;
      }

      final distanceKm = VendorDeliveryService.haversineDistanceKm(
        userLatitude,
        userLongitude,
        vendor.latitude!,
        vendor.longitude!,
      );

      final isServiceable = distanceKm <= vendor.deliveryRadiusKm;

      debugPrint('[DEBUG] Item Check: Vendor: ${vendor.storeName}');
      debugPrint(
          '  [DEBUG] User Location: Lat: $userLatitude, Lng: $userLongitude');
      debugPrint(
          '  [DEBUG] Vendor Location: Lat: ${vendor.latitude}, Lng: ${vendor.longitude}');
      debugPrint(
          '  [DEBUG] Distance: $distanceKm km, Radius: ${vendor.deliveryRadiusKm} km');
      debugPrint(
          '  [DEBUG] Result: ${isServiceable ? 'SERVICEABLE' : 'OUT OF RANGE'}');

      return isServiceable;
    }).toList();
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final products = await _getAvailableProducts(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
    final featured = products.where((product) => product.featured).toList();
    featured.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return featured.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getNewArrivals({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final products = await _getAvailableProducts(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getDeals({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final products = await _getAvailableProducts(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
    final deals =
        products.where((product) => product.discountPercent > 0).toList();
    deals.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return deals.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getRecommendedProducts({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final products = await _getAvailableProducts(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
    products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return products.take(10).toList();
  }

  Future<List<ProductEntity>> _getAvailableProducts({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final snapshot = await firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .limit(60)
        .get();

    final products = _mapProductsFromSnapshot(snapshot);
    final vendorIds = products
        .map((product) => product.vendorId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final vendorMap = await _vendorService.loadVendorMetadata(vendorIds);
    return _vendorService.enrichAndFilterProducts(
      products,
      vendorMap: vendorMap,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  List<ProductEntity> _mapProductsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => _mapProduct(doc))
        .whereType<ProductEntity>()
        .toList();
  }

  BannerEntity? _mapBanner(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      return BannerEntity(
        id: doc.id,
        title: _asString(data['title']),
        imageUrl: _asString(data['imageUrl']),
        linkType: _parseBannerLinkType(data['linkType']),
        linkId: _asNullableString(data['linkId'] ?? data['linkUrl']),
        isActive: _asBool(data['isActive'], fallback: _asBool(data['active'])),
        sortOrder: _asInt(data['sortOrder'], fallback: _asInt(data['order'])),
        createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
        updatedAt: _asDateTime(data['updatedAt']),
        vendorId: _asNullableString(data['vendorId']),
      );
    } catch (_) {
      return null;
    }
  }

  CategoryEntity? _mapCategory(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      return CategoryEntity(
        id: doc.id,
        name: _asString(data['name']),
        parentId: _asNullableString(data['parentId']),
        imageUrl: _asNullableString(data['imageUrl']),
        sortOrder: _asInt(data['sortOrder'], fallback: _asInt(data['order'])),
        createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
        updatedAt: _asDateTime(data['updatedAt']),
        vendorId: _asNullableString(data['vendorId']),
      );
    } catch (_) {
      return null;
    }
  }

  ProductEntity? _mapProduct(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return ProductModel.fromFirestore(doc).toEntity();
    } catch (_) {
      return null;
    }
  }

  BannerLinkType _parseBannerLinkType(dynamic value) {
    switch (_asString(value).toLowerCase()) {
      case 'category':
        return BannerLinkType.category;
      case 'product':
        return BannerLinkType.product;
      default:
        return BannerLinkType.none;
    }
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String? _asNullableString(dynamic value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (value is num) return value != 0;
    return fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
