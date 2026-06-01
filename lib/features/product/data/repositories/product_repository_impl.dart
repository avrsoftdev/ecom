import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProducts(
          categoryId: categoryId,
          searchQuery: searchQuery,
          limit: limit,
          offset: offset,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        return Right(products.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.getProductById(
          id,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        return Right(product.toEntity());
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProductsByCategory(
          categoryId,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        return Right(products.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.searchProducts(
          query,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        return Right(products.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}