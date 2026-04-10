import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_firestore_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl({
    required this.remote,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, DashboardMetricsEntity>> getMetrics() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final m = await remote.fetchDashboardMetrics();
      return Right(m);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SalesSeriesPoint>>> getSalesSeries({required int days}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final s = await remote.fetchSalesSeries(days: days);
      return Right(s);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<OrderEntity>> watchRecentOrders({int limit = 15}) {
    return remote.watchRecentOrders(limit: limit).map((list) => list.map((e) => e.toEntity()).toList());
  }

  @override
  Stream<List<ProductEntity>> watchTopSellingProducts({int limit = 8}) {
    return remote
        .watchTopSellingProducts(limit: limit)
        .map((list) => list.map((e) => e.toEntity()).toList());
  }
}
