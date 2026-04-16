import '../entities/product_entity.dart';
import '../entities/product_pricing.dart';

class PricingService {
  static double calculatePrice(ProductEntity product, double quantity) {
    // Find the best pricing tier for the given quantity
    ProductPricing? bestTier;
    
    for (final tier in product.pricingTiers) {
      if (tier.quantity <= quantity) {
        if (bestTier == null || tier.quantity > bestTier.quantity) {
          bestTier = tier;
        }
      }
    }
    
    // If no suitable tier found, use standard pricing
    if (bestTier == null) {
      return product.price * quantity;
    }
    
    // Calculate how many full tiers fit and remaining quantity
    final fullTiers = (quantity / bestTier.quantity).floor();
    final remainingQuantity = quantity % bestTier.quantity;
    
    // Calculate price for full tiers plus remaining quantity at standard price
    return (bestTier.price * fullTiers) + (product.price * remainingQuantity);
  }
  
  static List<ProductPricing> getApplicableTiers(ProductEntity product, double quantity) {
    return product.pricingTiers
        .where((tier) => tier.quantity <= quantity)
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity)); // Sort by quantity descending
  }
  
  static ProductPricing? getBestTier(ProductEntity product, double quantity) {
    ProductPricing? bestTier;
    
    for (final tier in product.pricingTiers) {
      if (tier.quantity <= quantity) {
        if (bestTier == null || tier.quantity > bestTier.quantity) {
          bestTier = tier;
        }
      }
    }
    
    return bestTier;
  }
  
  static double getEffectiveUnitPrice(ProductEntity product, double quantity) {
    return quantity > 0 ? calculatePrice(product, quantity) / quantity : 0;
  }
}
