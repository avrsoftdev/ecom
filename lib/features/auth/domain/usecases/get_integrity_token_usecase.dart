import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class GetIntegrityTokenUseCase implements UseCase<String?, GetIntegrityTokenParams> {
  final AuthRepository repository;

  GetIntegrityTokenUseCase(this.repository);

  @override
  Future<Either<Failure, String?>> call(GetIntegrityTokenParams params) async {
    return await repository.getIntegrityToken(nonce: params.nonce);
  }
}

class GetIntegrityTokenParams {
  final String? nonce;

  GetIntegrityTokenParams({this.nonce});
}
