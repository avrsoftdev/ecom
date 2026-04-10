import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final int stock;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// 0–100; effective sale price uses [effectivePrice].
  final double discountPercent;
  final bool featured;
  /// Extra gallery images; if empty, UI falls back to [imageUrl].
  final List<String> imageUrls;
  /// Aggregated when orders are marked delivered (admin).
  final int soldCount;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.stock,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.discountPercent = 0,
    this.featured = false,
    this.imageUrls = const [],
    this.soldCount = 0,
  });

  double get effectivePrice {
    if (discountPercent <= 0) return price;
    return price * (1 - discountPercent / 100);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        categoryId,
        stock,
        isAvailable,
        createdAt,
        updatedAt,
        discountPercent,
        featured,
        imageUrls,
        soldCount,
      ];
}