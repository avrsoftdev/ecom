import 'package:equatable/equatable.dart';

class ProductPricing extends Equatable {
  final double quantity;
  final double price;
  final String? description;

  const ProductPricing({
    required this.quantity,
    required this.price,
    this.description,
  });

  double get pricePerUnit => quantity > 0 ? price / quantity : 0;
  String get tierId => '${quantity.toStringAsFixed(3)}_${price.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [quantity, price, description];

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'price': price,
      'description': description,
    };
  }

  factory ProductPricing.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is num) {
        final d = value.toDouble();
        if (d.isNaN || d.isInfinite) return fallback;
        return d;
      }
      if (value is String) {
        final d = double.tryParse(value.trim());
        if (d == null || d.isNaN || d.isInfinite) return fallback;
        return d;
      }
      return fallback;
    }
    
    return ProductPricing(
      quantity: parseDouble(json['quantity'], fallback: 1),
      price: parseDouble(json['price']),
      description: json['description'] as String?,
    );
  }
}
