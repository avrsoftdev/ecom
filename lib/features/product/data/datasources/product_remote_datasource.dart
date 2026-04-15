import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  Future<ProductModel> getProductById(String id);

  Future<List<ProductModel>> getProductsByCategory(String categoryId);

  Future<List<ProductModel>> searchProducts(String query);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    Query<Map<String, dynamic>> query = firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Note: Firestore doesn't support full-text search natively
      // This is a simplified implementation
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
                   .where('name', isLessThan: searchQuery + '\uf8ff');
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    final products = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final doc = await firestore.collection('products').doc(id).get();
    if (!doc.exists) {
      throw Exception('Product not found');
    }
    return ProductModel.fromFirestore(doc);
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final snapshot = await firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final products = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    // Simplified search implementation
    final snapshot = await firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .orderBy('name')
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }
}
