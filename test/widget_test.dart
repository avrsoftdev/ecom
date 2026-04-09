import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:freshveggie/core/error/failures.dart';
import 'package:freshveggie/features/auth/domain/repositories/auth_repository.dart';
import 'package:freshveggie/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:freshveggie/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:freshveggie/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:freshveggie/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:freshveggie/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:freshveggie/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:freshveggie/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders key UI elements',
      (WidgetTester tester) async {
    final authCubit = AuthCubit(
      signInUseCase: SignInUseCase(_FakeAuthRepository()),
      signUpUseCase: SignUpUseCase(_FakeAuthRepository()),
      signInWithGoogleUseCase: SignInWithGoogleUseCase(_FakeAuthRepository()),
      signOutUseCase: SignOutUseCase(_FakeAuthRepository()),
      checkAuthStatusUseCase: CheckAuthStatusUseCase(_FakeAuthRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlocProvider.value(
          value: authCubit,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Bazariyo'), findsOneWidget);
    expect(find.text('Welcome back! Sign in to continue.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Or sign in with'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  User? get currentUser => null;

  @override
  Future<Either<Failure, UserCredential>> signIn(
      String email, String password) async {
    return Left(const AuthFailure('Not implemented in test.'));
  }

  @override
  Future<Either<Failure, UserCredential>> signInWithGoogle() async {
    return Left(const AuthFailure('Not implemented in test.'));
  }

  @override
  Future<Either<Failure, UserCredential>> signUp(
    String email,
    String password, {
    String? name,
    String? phone,
    String? address,
  }) async {
    return Left(const AuthFailure('Not implemented in test.'));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return const Right(null);
  }
}
