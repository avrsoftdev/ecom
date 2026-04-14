import 'package:dartz/dartz.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, HomeDataEntity>> getHomeData() async {
    if (await networkInfo.isConnected) {
      try {
        final banners = await remoteDataSource.getBanners();
        final categories = await remoteDataSource.getCategories();
        final featuredProducts = await remoteDataSource.getFeaturedProducts();
        final newArrivals = await remoteDataSource.getNewArrivals();
        final deals = await remoteDataSource.getDeals();
        final recommended = await remoteDataSource.getRecommendedProducts();

        return Right(HomeDataEntity(
          banners: banners,
          categories: categories,
          featuredProducts: featuredProducts,
          newArrivals: newArrivals,
          deals: deals,
          recommended: recommended,
        ));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}
