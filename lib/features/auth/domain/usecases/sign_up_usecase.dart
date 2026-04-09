import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserCredential, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserCredential>> call(SignUpParams params) {
    return repository.signUp(
      params.email,
      params.password,
      name: params.name,
      phone: params.phone,
      address: params.address,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String? name;
  final String? phone;
  final String? address;

  const SignUpParams({
    required this.email,
    required this.password,
    this.name,
    this.phone,
    this.address,
  });

  @override
  List<Object?> get props => [email, password, name, phone, address];
}

