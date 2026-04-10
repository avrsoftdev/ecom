import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/customer_profile_entity.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../domain/repositories/admin_customer_repository.dart';
import '../datasources/admin_firestore_datasource.dart';

class AdminCustomerRepositoryImpl implements AdminCustomerRepository {
  AdminCustomerRepositoryImpl({
    required this.remote,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final NetworkInfo networkInfo;

  @override
  Stream<List<CustomerProfileEntity>> watchCustomers({int limit = 200}) {
    return remote
        .watchCustomers(limit: limit)
        .map((list) => list.map((e) => e as CustomerProfileEntity).toList());
  }

  @override
  Future<Either<Failure, CustomerProfileEntity?>> getById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final u = await remote.getCustomer(id);
      return Right(u);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<OrderEntity>> watchOrdersForUser(String userId, {int limit = 50}) {
    return remote
        .watchOrdersForUser(userId, limit: limit)
        .map((list) => list.map((e) => e.toEntity()).toList());
  }
}
