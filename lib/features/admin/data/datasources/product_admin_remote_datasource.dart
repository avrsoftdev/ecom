import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../product/data/models/product_model.dart';

/// Admin-only product CRUD and streams. Uses collection `products`.
class ProductAdminRemoteDataSource {
  ProductAdminRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('products');

  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    StockFilterAdmin stock = StockFilterAdmin.any,
    String searchPrefix = '',
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true).limit(limit);
    if (categoryId != null && categoryId.isNotEmpty) {
      q = _col
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return q.snapshots().map((snap) {
      var list = snap.docs.map(ProductModel.fromFirestore).toList();
      if (searchPrefix.isNotEmpty) {
        final p = searchPrefix.toLowerCase();
        list = list.where((e) => e.name.toLowerCase().contains(p)).toList();
      }
      switch (stock) {
        case StockFilterAdmin.inStock:
          list = list.where((e) => e.stock > 0).toList();
          break;
        case StockFilterAdmin.outOfStock:
          list = list.where((e) => e.stock <= 0).toList();
          break;
        case StockFilterAdmin.low:
          list = list.where((e) => e.stock > 0 && e.stock < 10).toList();
          break;
        case StockFilterAdmin.any:
          break;
      }
      return list;
    });
  }

  Future<({List<ProductModel> items, String? lastId})> fetchPage({
    String? categoryId,
    StockFilterAdmin stock = StockFilterAdmin.any,
    String searchPrefix = '',
    required int pageSize,
    String? cursorDocumentId,
    String sortField = 'createdAt',
    bool descending = true,
  }) async {
    DocumentSnapshot<Map<String, dynamic>>? startAfter;
    if (cursorDocumentId != null) {
      final d = await _col.doc(cursorDocumentId).get();
      if (d.exists) startAfter = d;
    }
    Query<Map<String, dynamic>> q = _col;
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }
    q = q.orderBy(sortField, descending: descending).limit(pageSize);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    var list = snap.docs.map(ProductModel.fromFirestore).toList();
    if (searchPrefix.isNotEmpty) {
      final p = searchPrefix.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(p)).toList();
    }
    switch (stock) {
      case StockFilterAdmin.inStock:
        list = list.where((e) => e.stock > 0).toList();
        break;
      case StockFilterAdmin.outOfStock:
        list = list.where((e) => e.stock <= 0).toList();
        break;
      case StockFilterAdmin.low:
        list = list.where((e) => e.stock > 0 && e.stock < 10).toList();
        break;
      case StockFilterAdmin.any:
        break;
    }
    final lastId = snap.docs.isNotEmpty ? snap.docs.last.id : null;
    return (items: list, lastId: lastId);
  }

  Future<String> createProduct(ProductModel model) async {
    final doc = _col.doc();
    final now = DateTime.now();
    final data = model.toJson()
      ..remove('id')
      ..['createdAt'] = Timestamp.fromDate(now)
      ..['updatedAt'] = Timestamp.fromDate(now);
    await doc.set(data);
    return doc.id;
  }

  Future<void> updateProduct(String id, ProductModel model) async {
    final data = model.toJson()
      ..remove('id')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) => _col.doc(id).delete();

  Future<ProductModel> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) {
      throw StateError('Product not found');
    }
    return ProductModel.fromFirestore(doc);
  }
}

enum StockFilterAdmin { any, inStock, outOfStock, low }
