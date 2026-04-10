import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/order_entity.dart';

abstract class AdminOrderRepository {
  Stream<List<OrderEntity>> watchOrders({
    String? status,
    String? customerQuery,
    int limit,
  });

  Future<Either<Failure, OrderEntity?>> getOrderById(String id);

  Future<Either<Failure, void>> updateOrderStatus(String orderId, String newStatus);
}
