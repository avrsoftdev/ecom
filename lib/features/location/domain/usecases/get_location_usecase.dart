import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationAddressUseCase implements UseCase<String, NoParams> {
  final LocationRepository repository;

  GetCurrentLocationAddressUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await repository.getCurrentLocationAddress();
  }
}
