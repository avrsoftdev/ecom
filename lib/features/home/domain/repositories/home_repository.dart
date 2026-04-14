import 'package:dartz/dartz.dart';
import '../entities/home_data_entity.dart';
import '../../../../core/error/failures.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeDataEntity>> getHomeData();
}
