import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase implements UseCase<UserCredential, NoParams> {
  SignInWithGoogleUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserCredential>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
