import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../product/data/models/product_model.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/customer_profile_model.dart';
import '../models/order_model.dart';
import '../models/store_settings_model.dart';

const _kSettingsDoc = 'settings';
const _kStoreDoc = 'store';

class AdminFirestoreDataSource {
  AdminFirestoreDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  Future<DashboardMetricsEntity> fetchDashboardMetrics() async {
    final ordersSnap = await firestore.collection('orders').get();
    final productsSnap = await firestore.collection('products').get();
    final usersSnap = await firestore.collection('users').get();

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    var revenue = 0.0;
    var totalOrders = 0;
    var pending = 0;
    var newCustomers = 0;

    for (final d in ordersSnap.docs) {
      final data = d.data();
      final status = data['status'] as String? ?? 'pending';
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      if (status != 'cancelled') {
        revenue += total;
        totalOrders += 1;
      }
      if (status == 'pending' || status == 'processing') {
        pending += 1;
      }
    }

    for (final u in usersSnap.docs) {
      final data = u.data();
      final created = _ts(data['created_at']) ?? _ts(data['createdAt']);
      if (created != null && created.isAfter(weekAgo)) {
        newCustomers += 1;
      }
    }

    return DashboardMetricsEntity(
      totalRevenue: revenue,
      totalOrders: totalOrders,
      pendingOrders: pending,
      totalProducts: productsSnap.docs.length,
      newCustomersThisWeek: newCustomers,
    );
  }

  /// Buckets sales for the last [days] days (label = yyyy-MM-dd).
  Future<List<SalesSeriesPoint>> fetchSalesSeries({required int days}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final snap = await firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final map = <String, double>{};
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map[key] = 0;
    }

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      if (status == 'cancelled') continue;
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final created = _ts(data['createdAt']);
      if (created == null) continue;
      final key =
          '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + total;
    }

    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys.map((k) => SalesSeriesPoint(label: k, amount: map[k] ?? 0)).toList();
  }

  Stream<List<OrderModel>> watchRecentOrders({int limit = 15}) {
    return firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(OrderModel.fromFirestore).toList());
  }

  Stream<List<ProductModel>> watchTopSellingProducts({int limit = 8}) {
    return firestore
        .collection('products')
        .orderBy('soldCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ProductModel.fromFirestore).toList());
  }

  Stream<List<OrderModel>> watchOrders({
    String? status,
    String? customerQuery,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q = firestore.collectionGroup('orders').limit(limit);
    if (status != null && status.isNotEmpty && status != 'all') {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((s) {
      var list = s.docs.map(OrderModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length > limit) {
        list = list.take(limit).toList();
      }
      if (customerQuery != null && customerQuery.isNotEmpty) {
        final qy = customerQuery.toLowerCase();
        list = list
            .where(
              (o) =>
                  (o.customerEmail ?? '').toLowerCase().contains(qy) ||
                  (o.customerName ?? '').toLowerCase().contains(qy) ||
                  o.userId.toLowerCase().contains(qy),
            )
            .toList();
      }
      return list;
    });
  }

  Future<OrderModel?> getOrderById(String id) async {
    final rootDoc = await firestore.collection('orders').doc(id).get();
    if (rootDoc.exists) {
      return OrderModel.fromFirestore(rootDoc);
    }
    final nested = await firestore.collectionGroup('orders').where(FieldPath.documentId, isEqualTo: id).limit(1).get();
    if (nested.docs.isEmpty) return null;
    return OrderModel.fromFirestore(nested.docs.first);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, OrderModel current) async {
    final batch = firestore.batch();
    final ref = await _resolveOrderRef(orderId);
    if (ref == null) {
      throw StateError('Order not found');
    }
    batch.set(
      ref,
      {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (newStatus == 'delivered' && current.status != 'delivered') {
      for (final item in current.items) {
        final pRef = firestore.collection('products').doc(item.productId);
        batch.set(
          pRef,
          {
            'soldCount': FieldValue.increment(item.quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  Future<DocumentReference<Map<String, dynamic>>?> _resolveOrderRef(String orderId) async {
    final rootRef = firestore.collection('orders').doc(orderId);
    final rootSnap = await rootRef.get();
    if (rootSnap.exists) {
      return rootRef;
    }

    final nested = await firestore
        .collectionGroup('orders')
        .where(FieldPath.documentId, isEqualTo: orderId)
        .limit(1)
        .get();
    if (nested.docs.isEmpty) {
      return null;
    }
    return nested.docs.first.reference;
  }

  Stream<List<CategoryModel>> watchCategories() {
    return firestore
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(CategoryModel.fromFirestore).toList());
  }

  Future<String> createCategory(CategoryModel model) async {
    final doc = firestore.collection('categories').doc();
    await doc.set({
      'name': model.name,
      'parentId': model.parentId,
      'imageUrl': model.imageUrl,
      'sortOrder': model.sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateCategory(String id, CategoryModel model) async {
    await firestore.collection('categories').doc(id).set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) =>
      firestore.collection('categories').doc(id).delete();

  Stream<List<BannerModel>> watchBanners() {
    return firestore
        .collection('banners')
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(BannerModel.fromFirestore).toList());
  }

  Future<String> createBanner(BannerModel model) async {
    final doc = firestore.collection('banners').doc();
    final data = Map<String, dynamic>.from(model.toFirestore())
      ..remove('createdAt')
      ..remove('updatedAt');
    await doc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateBanner(String id, BannerModel model) async {
    await firestore.collection('banners').doc(id).set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteBanner(String id) => firestore.collection('banners').doc(id).delete();

  Stream<List<CustomerProfileModel>> watchCustomers({int limit = 200}) {
    return firestore.collection('users').limit(limit).snapshots().map(
          (s) => s.docs.map(CustomerProfileModel.fromFirestore).toList(),
        );
  }

  Future<CustomerProfileModel?> getCustomer(String id) async {
    final doc = await firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return CustomerProfileModel.fromFirestore(doc);
  }

  Stream<List<OrderModel>> watchOrdersForUser(String userId, {int limit = 50}) {
    return firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<StoreSettingsModel> getStoreSettings() async {
    final doc = await firestore.collection(_kSettingsDoc).doc(_kStoreDoc).get();
    if (!doc.exists || doc.data() == null) {
      return const StoreSettingsModel(deliveryCharge: 0, taxPercent: 0);
    }
    return StoreSettingsModel.fromJson(doc.data()!);
  }

  Future<void> saveStoreSettings(StoreSettingsModel model) async {
    await firestore.collection(_kSettingsDoc).doc(_kStoreDoc).set(model.toJson(), SetOptions(merge: true));
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
