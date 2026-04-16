import 'package:equatable/equatable.dart';
import 'product_pricing.dart';
import 'product_unit_type.dart';

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
  /// Unit type for selling the product (weight, quantity, volume, pack)
  final ProductUnitType unitType;
  /// Different pricing tiers for the product (e.g., 0.5kg, 1kg, 2kg)
  final List<ProductPricing> pricingTiers;

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
    this.unitType = ProductUnitType.quantity,
    this.pricingTiers = const [],
  });

  double get effectivePrice {
    if (discountPercent <= 0) return price;
    return price * (1 - discountPercent / 100);
  }

  /// Calculate price for given quantity using best available pricing tier
  double calculatePrice(double quantity) {
    // Find the best pricing tier for the given quantity
    ProductPricing? bestTier;
    
    for (final tier in pricingTiers) {
      if (tier.quantity <= quantity) {
        if (bestTier == null || tier.quantity > bestTier.quantity) {
          bestTier = tier;
        }
      }
    }
    
    // If no suitable tier found, use standard pricing
    if (bestTier == null) {
      return price * quantity;
    }
    
    // Calculate how many full tiers fit and remaining quantity
    final fullTiers = (quantity / bestTier.quantity).floor();
    final remainingQuantity = quantity % bestTier.quantity;
    
    // Calculate price for full tiers plus remaining quantity at standard price
    return (bestTier.price * fullTiers) + (price * remainingQuantity);
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
        unitType,
        pricingTiers,
      ];
}