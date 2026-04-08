import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsParams params) {
    return repository.getProducts(
      categoryId: params.categoryId,
      searchQuery: params.searchQuery,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetProductsParams extends Equatable {
  final String? categoryId;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const GetProductsParams({
    this.categoryId,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [categoryId, searchQuery, limit, offset];
}