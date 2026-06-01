import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/home_data_entity.dart';
import '../repositories/home_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetHomeDataUseCase
    implements UseCase<HomeDataEntity, GetHomeDataParams> {
  final HomeRepository repository;

  GetHomeDataUseCase(this.repository);

  @override
  Future<Either<Failure, HomeDataEntity>> call(GetHomeDataParams params) async {
    return await repository.getHomeData(
      userLatitude: params.userLatitude,
      userLongitude: params.userLongitude,
    );
  }
}

class GetHomeDataParams extends Equatable {
  const GetHomeDataParams({
    this.userLatitude,
    this.userLongitude,
  });

  final double? userLatitude;
  final double? userLongitude;

  @override
  List<Object?> get props => [userLatitude, userLongitude];
}
