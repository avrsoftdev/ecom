import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, ProductEntity>> getProductById(String id);

  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(String categoryId);

  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query);
}