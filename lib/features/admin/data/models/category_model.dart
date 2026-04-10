import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    super.parentId,
    super.imageUrl,
    super.sortOrder = 0,
    required super.createdAt,
    super.updatedAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      parentId: data['parentId'] as String?,
      imageUrl: data['imageUrl'] as String?,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: _ts(data['createdAt']) ?? DateTime.now(),
      updatedAt: _ts(data['updatedAt']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'parentId': parentId,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
