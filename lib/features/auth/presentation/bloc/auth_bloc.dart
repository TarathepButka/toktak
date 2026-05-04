// features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

part 'auth_bloc.freezed.dart';

// ─── Events ──────────────────────────────────────────────────

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkAuth() = _CheckAuth;
  const factory AuthEvent.loginWithGoogle() = _LoginWithGoogle;

  const factory AuthEvent.loginWithLine() = _LoginWithLine;
  const factory AuthEvent.logout() = _Logout;
}

// ─── States ──────────────────────────────────────────────────

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(Failure failure) = _Error;
}

// ─── BLoC ────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<_CheckAuth>(_onCheckAuth);
    on<_LoginWithGoogle>(_onLoginWithGoogle);

    on<_LoginWithLine>(_onLoginWithLine);
    on<_Logout>(_onLogout);
  }

  Future<void> _onCheckAuth(_CheckAuth event, Emitter<AuthState> emit) async {
    if (_authRepository.isLoggedIn) {
      final result = await _authRepository.getCurrentUser();
      result.fold(
        (failure) => emit(const AuthState.unauthenticated()),
        (user) => emit(AuthState.authenticated(user)),
      );
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginWithGoogle(_LoginWithGoogle event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await _authRepository.loginWithGoogle();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (authResponse) => emit(AuthState.authenticated(authResponse.user)),
    );
  }

  Future<void> _onLoginWithLine(_LoginWithLine event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await _authRepository.loginWithLine();
    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (authResponse) => emit(AuthState.authenticated(authResponse.user)),
    );
  }

  Future<void> _onLogout(_Logout event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }
}
