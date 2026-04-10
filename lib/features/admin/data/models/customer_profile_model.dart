import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/domain/entities/customer_profile_entity.dart';

class CustomerProfileModel extends CustomerProfileEntity {
  const CustomerProfileModel({
    required super.id,
    required super.email,
    super.displayName,
    super.phone,
    super.address,
    super.photoUrl,
    required super.role,
    required super.createdAt,
    super.lastSignInAt,
  });

  factory CustomerProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CustomerProfileModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      photoUrl: data['photo_url'] as String?,
      role: data['role'] as String? ?? 'customer',
      createdAt: _ts(data['created_at']) ?? DateTime.now(),
      lastSignInAt: _ts(data['last_sign_in_at']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
