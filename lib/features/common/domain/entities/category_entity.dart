import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    this.parentId,
    this.imageUrl,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final String? imageUrl;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isSubCategory => parentId != null && parentId!.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, name, parentId, imageUrl, sortOrder, createdAt, updatedAt];
}
