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
  Future<Either<Failure, UserCredential>> signIn(
      String email, String password) async {
    try {
      final result =
          await remoteDataSource.signInWithEmailAndPassword(email, password);
      await _persistAuthenticatedUser(result.user!);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorToMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signUp(
    String email,
    String password, {
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final result =
          await remoteDataSource.signUpWithEmailAndPassword(email, password);
      await _persistAuthenticatedUser(
        result.user!,
        name: name,
        phone: phone,
        address: address,
      );
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
  Future<Either<Failure, String?>> getUserRole(String uid) async {
    try {
      final role = await remoteDataSource.getUserRole(uid);
      return Right(role);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  User? get currentUser => remoteDataSource.currentUser;

  Future<void> _persistAuthenticatedUser(
    User user, {
    String? name,
    String? phone,
    String? address,
  }) async {
    var authUser = AuthUserModel.fromFirebaseUser(user);

    // Override with custom values if provided
    if (name != null || phone != null || address != null) {
      authUser = AuthUserModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: name ?? authUser.displayName,
        photoUrl: authUser.photoUrl,
        phone: phone,
        address: address,
        providerIds: authUser.providerIds,
      );
    }

    await sharedPreferences.setString('user_id', authUser.uid);
    await sharedPreferences.setString('user_email', authUser.email);
    await sharedPreferences.setString('user_name', authUser.displayName ?? '');
    await sharedPreferences.setString('user_photo', authUser.photoUrl ?? '');
    if (phone != null) await sharedPreferences.setString('user_phone', phone);
    if (address != null)
      await sharedPreferences.setString('user_address', address);

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
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'invalid-api-key':
        return 'Invalid Firebase configuration. Check the web API key.';
      case 'operation-not-allowed':
        return 'This sign-in method is disabled. Enable it in Firebase Authentication.';
      case 'unauthorized-domain':
        return 'This domain is not authorized for Firebase Auth. Add it in the Firebase console.';
      case 'operation-not-supported-in-this-environment':
        return 'Operation not supported in this environment. Check browser settings and authorized domains.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
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
      case 'configuration-not-found':
        return 'Firebase project configuration not found.';
      case 'internal-error':
        return 'Unexpected error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
