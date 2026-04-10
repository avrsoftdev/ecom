import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/customer_profile_entity.dart';
import '../../../common/domain/entities/order_entity.dart';

abstract class AdminCustomerRepository {
  Stream<List<CustomerProfileEntity>> watchCustomers({int limit});

  Future<Either<Failure, CustomerProfileEntity?>> getById(String id);

  Stream<List<OrderEntity>> watchOrdersForUser(String userId, {int limit});
}
