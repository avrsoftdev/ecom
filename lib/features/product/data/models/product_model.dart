import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    required super.categoryId,
    required super.stock,
    required super.isAvailable,
    required super.createdAt,
    required super.updatedAt,
    super.discountPercent = 0,
    super.featured = false,
    super.imageUrls = const [],
    super.soldCount = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: _parseTime(json['createdAt']),
      updatedAt: _parseTime(json['updatedAt']),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      featured: json['featured'] as bool? ?? false,
      imageUrls: imageUrls,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _parseTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      imageUrl: entity.imageUrl,
      categoryId: entity.categoryId,
      stock: entity.stock,
      isAvailable: entity.isAvailable,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      discountPercent: entity.discountPercent,
      featured: entity.featured,
      imageUrls: entity.imageUrls,
      soldCount: entity.soldCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'stock': stock,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'discountPercent': discountPercent,
      'featured': featured,
      'imageUrls': imageUrls,
      'soldCount': soldCount,
    };
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      categoryId: categoryId,
      stock: stock,
      isAvailable: isAvailable,
      createdAt: createdAt,
      updatedAt: updatedAt,
      discountPercent: discountPercent,
      featured: featured,
      imageUrls: imageUrls,
      soldCount: soldCount,
    );
  }
}