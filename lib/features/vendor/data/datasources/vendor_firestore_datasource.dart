import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor_application_model.dart';

class VendorFirestoreDataSource {
  VendorFirestoreDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  Future<void> createVendorApplication(VendorApplicationModel application) async {
    final doc = firestore.collection('vendor_applications').doc(application.id);
    await doc.set(application.toFirestore());
  }

  Future<VendorApplicationModel?> getVendorApplicationByUserId(
      String userId) async {
    final snap = await firestore
        .collection('vendor_applications')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return VendorApplicationModel.fromFirestore(snap.docs.first);
  }

  Stream<List<VendorApplicationModel>> watchAllVendorApplications({
    String? status,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q =
        firestore.collection('vendor_applications').orderBy('created_at', descending: true);
    if (status != null && status.isNotEmpty && status != 'all') {
      q = q.where('status', isEqualTo: status);
    }
    q = q.limit(limit);
    return q.snapshots().map(
          (s) => s.docs.map(VendorApplicationModel.fromFirestore).toList(),
        );
  }

  Future<void> updateVendorApplicationStatus({
    required String applicationId,
    required String status,
    String? reviewedBy,
    String? reviewComment,
  }) async {
    await firestore.collection('vendor_applications').doc(applicationId).set({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
      'reviewed_by': reviewedBy,
      'review_comment': reviewComment,
    }, SetOptions(merge: true));
  }

  Future<void> updateVendorApplication(VendorApplicationModel application) async {
    await firestore
        .collection('vendor_applications')
        .doc(application.id)
        .set(application.toFirestore(), SetOptions(merge: true));
  }
}
