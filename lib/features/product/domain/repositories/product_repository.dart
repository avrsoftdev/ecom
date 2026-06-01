import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
    double? userLatitude,
    double? userLongitude,
  });

  Future<Either<Failure, ProductEntity>> getProductById(
    String id, {
    double? userLatitude,
    double? userLongitude,
  });

  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    double? userLatitude,
    double? userLongitude,
  });

  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    String query, {
    double? userLatitude,
    double? userLongitude,
  });
}