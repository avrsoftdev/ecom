import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';

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
      await _persistAuthenticatedUser(result.user!);
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
      await _persistAuthenticatedUser(result.user!);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorToMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signInWithGoogle() async {
    try {
      final result = await remoteDataSource.signInWithGoogle();
      await _persistAuthenticatedUser(result.user!);
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

  Future<void> _persistAuthenticatedUser(User user) async {
    final authUser = AuthUserModel.fromFirebaseUser(user);

    await sharedPreferences.setString('user_id', authUser.uid);
    await sharedPreferences.setString('user_email', authUser.email);
    await sharedPreferences.setString('user_name', authUser.displayName ?? '');
    await sharedPreferences.setString('user_photo', authUser.photoUrl ?? '');

    try {
      await remoteDataSource.upsertUserProfile(authUser);
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore profile sync skipped: ${e.code} ${e.message ?? ''}'.trim(),
      );
    }
  }

  Future<void> _clearUserSession() async {
    await sharedPreferences.remove('user_id');
    await sharedPreferences.remove('user_email');
    await sharedPreferences.remove('user_name');
    await sharedPreferences.remove('user_photo');
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
      case 'sign_in_canceled':
        return 'Google sign in was canceled.';
      case 'network-request-failed':
        return 'A network error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
