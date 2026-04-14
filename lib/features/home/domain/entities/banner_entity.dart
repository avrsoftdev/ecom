import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String? description;
  final int order;
  final bool isActive;

  const BannerEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.description,
    required this.order,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        imageUrl,
        linkUrl,
        description,
        order,
        isActive,
      ];
}
