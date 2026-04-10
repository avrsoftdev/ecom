import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../entities/dashboard_metrics_entity.dart';

abstract class AdminDashboardRepository {
  Future<Either<Failure, DashboardMetricsEntity>> getMetrics();

  Future<Either<Failure, List<SalesSeriesPoint>>> getSalesSeries({required int days});

  Stream<List<OrderEntity>> watchRecentOrders({int limit});

  Stream<List<ProductEntity>> watchTopSellingProducts({int limit});
}
