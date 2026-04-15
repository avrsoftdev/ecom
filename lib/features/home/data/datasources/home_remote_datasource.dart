import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/domain/entities/banner_entity.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class HomeRemoteDataSource {
  Future<List<BannerEntity>> getBanners();
  Future<List<CategoryEntity>> getCategories();
  Future<List<ProductEntity>> getFeaturedProducts();
  Future<List<ProductEntity>> getNewArrivals();
  Future<List<ProductEntity>> getDeals();
  Future<List<ProductEntity>> getRecommendedProducts();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Future<List<BannerEntity>> getBanners() async {
    final snapshot = await firestore.collection('banners').get();

    final banners = snapshot.docs
        .map((doc) => _mapBanner(doc))
        .whereType<BannerEntity>()
        .where((banner) => banner.isActive)
        .toList();

    banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return banners;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final snapshot = await firestore.collection('categories').get();

    final categories = snapshot.docs
        .map((doc) => _mapCategory(doc))
        .whereType<CategoryEntity>()
        .toList();

    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts() async {
    final products = await _getAvailableProducts();
    final featured = products.where((product) => product.featured).toList();
    featured.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return featured.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getNewArrivals() async {
    final products = await _getAvailableProducts();
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getDeals() async {
    final products = await _getAvailableProducts();
    final deals = products.where((product) => product.discountPercent > 0).toList();
    deals.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return deals.take(10).toList();
  }

  @override
  Future<List<ProductEntity>> getRecommendedProducts() async {
    final products = await _getAvailableProducts();
    products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return products.take(10).toList();
  }

  Future<List<ProductEntity>> _getAvailableProducts() async {
    final snapshot = await firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .limit(60)
        .get();

    return _mapProductsFromSnapshot(snapshot);
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
      );
    } catch (_) {
      return null;
    }
  }

  CategoryEntity? _mapCategory(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
      );
    } catch (_) {
      return null;
    }
  }

  ProductEntity? _mapProduct(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      final imageUrls = _asStringList(data['imageUrls']);
      final primaryImage = _asString(data['imageUrl']).isNotEmpty
          ? _asString(data['imageUrl'])
          : (imageUrls.isNotEmpty ? imageUrls.first : '');

      return ProductEntity(
        id: doc.id,
        name: _asString(data['name']),
        description: _asString(data['description']),
        price: _asDouble(data['price']),
        imageUrl: primaryImage,
        categoryId: _asString(data['categoryId']),
        stock: _asInt(data['stock']),
        isAvailable: _asBool(
          data['isAvailable'],
          fallback: _asBool(data['isActive'], fallback: true),
        ),
        createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
        updatedAt: _asDateTime(data['updatedAt']) ?? DateTime.now(),
        discountPercent: _asDouble(data['discountPercent']),
        featured: _asBool(
          data['featured'],
          fallback: _asBool(data['isFeatured']),
        ),
        imageUrls: imageUrls,
        soldCount: _asInt(data['soldCount']),
      );
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

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
