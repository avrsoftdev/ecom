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
    return ProductPricing(
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
    );
  }
}
