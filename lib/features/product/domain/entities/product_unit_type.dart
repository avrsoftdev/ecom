enum ProductUnitType {
  weight('WEIGHT', 'kg'),
  quantity('QUANTITY', 'pieces'),
  volume('VOLUME', 'liters'),
  pack('PACK', 'packs');

  const ProductUnitType(this.code, this.displayUnit);

  final String code;
  final String displayUnit;

  static ProductUnitType fromCode(String code) {
    return values.firstWhere(
      (type) => type.code == code,
      orElse: () => ProductUnitType.quantity,
    );
  }

  String get displayName {
    switch (this) {
      case ProductUnitType.weight:
        return 'Weight';
      case ProductUnitType.quantity:
        return 'Quantity';
      case ProductUnitType.volume:
        return 'Volume';
      case ProductUnitType.pack:
        return 'Pack';
    }
  }
}
