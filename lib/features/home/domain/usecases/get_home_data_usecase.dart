import 'package:dartz/dartz.dart';
import '../entities/home_data_entity.dart';
import '../repositories/home_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetHomeDataUseCase implements UseCase<HomeDataEntity, NoParams> {
  final HomeRepository repository;

  GetHomeDataUseCase(this.repository);

  @override
  Future<Either<Failure, HomeDataEntity>> call(NoParams params) async {
    return await repository.getHomeData();
  }
}
