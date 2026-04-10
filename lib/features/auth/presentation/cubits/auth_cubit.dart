import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/auth/auth_role_notifier.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_user_role_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetUserRoleUseCase getUserRoleUseCase;

  AuthCubit({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.checkAuthStatusUseCase,
    required this.getUserRoleUseCase,
  }) : super(AuthInitial());

  Future<void> _emitAuthenticated(User user) async {
    final roleResult = await getUserRoleUseCase(GetUserRoleParams(uid: user.uid));
    roleResult.fold(
      (failure) {
        AuthRoleNotifier.instance.clear();
        emit(AuthError(failure.message));
      },
      (role) {
        AuthRoleNotifier.instance.setRole(role);
        emit(Authenticated(user, role: role));
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());

    final params = SignInParams(email: email, password: password);
    final result = await signInUseCase(params);

    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (userCredential) async {
        await _emitAuthenticated(userCredential.user!);
      },
    );
  }

  Future<void> signUp(
    String email,
    String password, {
    String? name,
    String? phone,
    String? address,
  }) async {
    emit(AuthLoading());

    final params = SignUpParams(
      email: email,
      password: password,
      name: name,
      phone: phone,
      address: address,
    );
    final result = await signUpUseCase(params);

    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (userCredential) async {
        await _emitAuthenticated(userCredential.user!);
      },
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    final result = await signInWithGoogleUseCase(NoParams());

    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (userCredential) async {
        await _emitAuthenticated(userCredential.user!);
      },
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());

    final result = await signOutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        AuthRoleNotifier.instance.clear();
        emit(Unauthenticated());
      },
    );
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    final result = await checkAuthStatusUseCase(NoParams());

    await result.fold<Future<void>>(
      (failure) async {
        AuthRoleNotifier.instance.clear();
        emit(AuthError(failure.message));
      },
      (user) async {
        if (user != null) {
          await _emitAuthenticated(user);
        } else {
          AuthRoleNotifier.instance.clear();
          emit(Unauthenticated());
        }
      },
    );
  }
}
