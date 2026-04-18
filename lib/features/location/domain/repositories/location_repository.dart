import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class LocationRepository {
  Future<Either<Failure, String>> getCurrentLocationAddress();
}
