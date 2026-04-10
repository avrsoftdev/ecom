import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class GetUserRoleParams extends Equatable {
  const GetUserRoleParams({required this.uid});

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class GetUserRoleUseCase implements UseCase<String?, GetUserRoleParams> {
  GetUserRoleUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, String?>> call(GetUserRoleParams params) {
    return repository.getUserRole(params.uid);
  }
}
