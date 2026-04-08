import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    try {
      final user = repository.currentUser;
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}