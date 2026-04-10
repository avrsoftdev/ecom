import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../domain/repositories/admin_order_repository.dart';
import '../datasources/admin_firestore_datasource.dart';

class AdminOrderRepositoryImpl implements AdminOrderRepository {
  AdminOrderRepositoryImpl({
    required this.remote,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final NetworkInfo networkInfo;

  @override
  Stream<List<OrderEntity>> watchOrders({
    String? status,
    String? customerQuery,
    int limit = 50,
  }) {
    return remote
        .watchOrders(status: status, customerQuery: customerQuery, limit: limit)
        .map((list) => list.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Either<Failure, OrderEntity?>> getOrderById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final o = await remote.getOrderById(id);
      return Right(o?.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String newStatus) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final current = await remote.getOrderById(orderId);
      if (current == null) {
        return const Left(ServerFailure('Order not found'));
      }
      await remote.updateOrderStatus(orderId, newStatus, current);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
