import 'package:dartz/dartz.dart';

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

      return Right(
        HomeDataEntity(
          banners: banners,
          categories: categories,
          featuredProducts: featuredProducts,
          newArrivals: newArrivals,
          deals: deals,
          recommended: recommended,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<List<T>> _safeLoad<T>(Future<List<T>> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return <T>[];
    }
  }
}
