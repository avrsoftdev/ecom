import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, UserCredential>> signIn(String email, String password) async {
    try {
      final result = await remoteDataSource.signInWithEmailAndPassword(email, password);
      await _saveUserSession(result.user!);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorToMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signUp(String email, String password) async {
    try {
      final result = await remoteDataSource.signUpWithEmailAndPassword(email, password);
      await _saveUserSession(result.user!);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorToMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await _clearUserSession();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  User? get currentUser => remoteDataSource.currentUser;

  Future<void> _saveUserSession(User user) async {
    await sharedPreferences.setString('user_id', user.uid);
    await sharedPreferences.setString('user_email', user.email ?? '');
  }

  Future<void> _clearUserSession() async {
    await sharedPreferences.remove('user_id');
    await sharedPreferences.remove('user_email');
  }

  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}