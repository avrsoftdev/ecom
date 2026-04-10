import 'package:equatable/equatable.dart';

/// Link target for homepage carousel items.
enum BannerLinkType {
  none,
  category,
  product,
}

class BannerEntity extends Equatable {
  const BannerEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkType,
    this.linkId,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final BannerLinkType linkType;
  final String? linkId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        title,
        imageUrl,
        linkType,
        linkId,
        isActive,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
