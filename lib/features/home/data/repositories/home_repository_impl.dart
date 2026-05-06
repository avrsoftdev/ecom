import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final HomeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, HomeDataEntity>> getHomeData() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final banners = await _safeLoad(remoteDataSource.getBanners);
      final categories = await _safeLoad(remoteDataSource.getCategories);
      final featuredProducts = await _safeLoad(remoteDataSource.getFeaturedProducts);
      final newArrivals = await _safeLoad(remoteDataSource.getNewArrivals);
      final deals = await _safeLoad(remoteDataSource.getDeals);
      final recommended = await _safeLoad(remoteDataSource.getRecommendedProducts);

      final homeData = HomeDataEntity(
        banners: banners ?? [],
        categories: categories ?? [],
        featuredProducts: featuredProducts ?? [],
        newArrivals: newArrivals ?? [],
        deals: deals ?? [],
        recommended: recommended ?? [],
      );

      return Right(homeData);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<List<T>> _safeLoad<T>(Future<List<T>> Function() loader) async {
    try {
      final result = await loader();
      return result.where((item) => item != null).cast<T>().toList();
    } catch (e, stackTrace) {
      debugPrint('HomeRepositoryImpl load failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return <T>[];
    }
  }
}
