import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final int order;
  final bool isActive;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    required this.order,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        description,
        order,
        isActive,
      ];
}
