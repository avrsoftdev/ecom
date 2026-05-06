import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationAddressUseCase implements UseCase<LocationEntity, NoParams> {
  final LocationRepository repository;

  GetCurrentLocationAddressUseCase(this.repository);

  @override
  Future<Either<Failure, LocationEntity>> call(NoParams params) async {
    return await repository.getCurrentLocationAddress();
  }
}
