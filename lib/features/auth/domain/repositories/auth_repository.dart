import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserCredential>> signIn(String email, String password);
  Future<Either<Failure, UserCredential>> signUp(String email, String password);
  Future<Either<Failure, UserCredential>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}
