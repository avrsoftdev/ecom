import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
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
    final snapshot = await firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .get();

    final banners = snapshot.docs.map((doc) {
      final data = doc.data();
      return BannerEntity(
        id: doc.id,
        title: data['title'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        linkUrl: data['linkUrl'],
        description: data['description'],
        order: data['order'] ?? 0,
        isActive: data['isActive'] ?? false,
      );
    }).toList();

    banners.sort((a, b) => a.order.compareTo(b.order));
    return banners;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final snapshot = await firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();

    final categories = snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryEntity(
        id: doc.id,
        name: data['name'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        description: data['description'],
        order: data['order'] ?? 0,
        isActive: data['isActive'] ?? false,
      );
    }).toList();

    categories.sort((a, b) => a.order.compareTo(b.order));
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
        .limit(40)
        .get();

    return _mapProductsFromSnapshot(snapshot);
  }

  List<ProductEntity> _mapProductsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ProductEntity(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        imageUrl: data['imageUrl'] ?? '',
        categoryId: data['categoryId'] ?? '',
        stock: data['stock'] ?? 0,
        isAvailable: data['isAvailable'] ?? true,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        discountPercent: (data['discountPercent'] ?? 0).toDouble(),
        featured: data['featured'] ?? false,
        imageUrls: List<String>.from(data['imageUrls'] ?? const []),
        soldCount: data['soldCount'] ?? 0,
      );
    }).toList();
  }
}
