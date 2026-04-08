import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthCubit({
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial());

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());

    final params = SignInParams(email: email, password: password);
    final result = await signInUseCase(params);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (userCredential) => emit(Authenticated(userCredential.user!)),
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());

    final result = await signOutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> checkAuthStatus() async {
    final result = await checkAuthStatusUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }
}
