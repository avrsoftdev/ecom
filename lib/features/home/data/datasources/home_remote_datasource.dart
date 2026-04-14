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
  final FirebaseFirestore firestore;

  HomeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<BannerEntity>> getBanners() async {
    final snapshot = await firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) {
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
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final snapshot = await firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) {
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
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts() async {
    final snapshot = await firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return _mapProductsFromSnapshot(snapshot);
  }

  @override
  Future<List<ProductEntity>> getNewArrivals() async {
    final snapshot = await firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return _mapProductsFromSnapshot(snapshot);
  }

  @override
  Future<List<ProductEntity>> getDeals() async {
    final snapshot = await firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('discountPercentage', isGreaterThan: 0)
        .orderBy('discountPercentage', descending: true)
        .limit(10)
        .get();

    return _mapProductsFromSnapshot(snapshot);
  }

  @override
  Future<List<ProductEntity>> getRecommendedProducts() async {
    // For now, return popular products. Later this can be personalized
    final snapshot = await firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(10)
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
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        soldCount: data['soldCount'] ?? 0,
      );
    }).toList();
  }
}
