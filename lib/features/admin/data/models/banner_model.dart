import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  const BannerModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    required super.linkType,
    super.linkId,
    super.isActive = true,
    super.sortOrder = 0,
    required super.createdAt,
    super.updatedAt,
  });

  static BannerLinkType _linkType(String? raw) {
    switch (raw) {
      case 'category':
        return BannerLinkType.category;
      case 'product':
        return BannerLinkType.product;
      default:
        return BannerLinkType.none;
    }
  }

  static String _linkTypeToString(BannerLinkType t) {
    switch (t) {
      case BannerLinkType.category:
        return 'category';
      case BannerLinkType.product:
        return 'product';
      case BannerLinkType.none:
        return 'none';
    }
  }

  factory BannerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BannerModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      linkType: _linkType(data['linkType'] as String?),
      linkId: data['linkId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
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
      'title': title,
      'imageUrl': imageUrl,
      'linkType': _linkTypeToString(linkType),
      'linkId': linkId,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
