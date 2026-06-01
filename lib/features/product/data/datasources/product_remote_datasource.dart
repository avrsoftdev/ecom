import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/vendor_delivery_service.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
    double? userLatitude,
    double? userLongitude,
  });

  Future<ProductModel> getProductById(
    String id, {
    double? userLatitude,
    double? userLongitude,
  });

  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    double? userLatitude,
    double? userLongitude,
  });

  Future<List<ProductModel>> searchProducts(
    String query, {
    double? userLatitude,
    double? userLongitude,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;
  final VendorDeliveryService vendorDeliveryService;

  ProductRemoteDataSourceImpl({
    required this.firestore,
    VendorDeliveryService? vendorDeliveryService,
  }) : vendorDeliveryService = vendorDeliveryService ??
            VendorDeliveryService(firestore: firestore);

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
    double? userLatitude,
    double? userLongitude,
  }) async {
    Query<Map<String, dynamic>> query =
        firestore.collection('products').where('isAvailable', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Note: Firestore doesn't support full-text search natively
      // This is a simplified implementation using prefix matching
      // IMPORTANT: This requires a composite index on (isAvailable, name)
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: searchQuery + '\uf8ff')
          .orderBy('name');
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    final products =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

    if (searchQuery == null || searchQuery.isEmpty) {
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return _attachVendorMetadata(
      products,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  @override
  Future<ProductModel> getProductById(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    final doc = await firestore.collection('products').doc(id).get();
    if (!doc.exists) {
      throw Exception('Product not found');
    }
    final product = ProductModel.fromFirestore(doc);
    final products = await _attachVendorMetadata(
      [product],
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
    return products.first;
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    final snapshot = await firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final products =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _attachVendorMetadata(
      products,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    // Simplified search implementation using prefix matching
    // IMPORTANT: This requires a composite index on (isAvailable, name)
    final snapshot = await firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .orderBy('name')
        .limit(20)
        .get();

    final products =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    return _attachVendorMetadata(
      products,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }

  Future<List<ProductModel>> _attachVendorMetadata(
    List<ProductModel> products, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (products.isEmpty) return products;

    final vendorIds = products
        .map((product) => product.vendorId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final vendorMap = await vendorDeliveryService.loadVendorMetadata(vendorIds);
    final filtered = vendorDeliveryService.enrichAndFilterProducts(
      products,
      vendorMap: vendorMap,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    return filtered.map(ProductModel.fromEntity).toList(growable: false);
  }
}
