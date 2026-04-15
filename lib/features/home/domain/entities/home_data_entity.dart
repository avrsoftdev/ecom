import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/banner_entity.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

class HomeDataEntity extends Equatable {
  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<ProductEntity> featuredProducts;
  final List<ProductEntity> newArrivals;
  final List<ProductEntity> deals;
  final List<ProductEntity> recommended;

  const HomeDataEntity({
    required this.banners,
    required this.categories,
    required this.featuredProducts,
    required this.newArrivals,
    required this.deals,
    required this.recommended,
  });

  @override
  List<Object?> get props => [
        banners,
        categories,
        featuredProducts,
        newArrivals,
        deals,
        recommended,
      ];

  HomeDataEntity copyWith({
    List<BannerEntity>? banners,
    List<CategoryEntity>? categories,
    List<ProductEntity>? featuredProducts,
    List<ProductEntity>? newArrivals,
    List<ProductEntity>? deals,
    List<ProductEntity>? recommended,
  }) {
    return HomeDataEntity(
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      deals: deals ?? this.deals,
      recommended: recommended ?? this.recommended,
    );
  }
}
