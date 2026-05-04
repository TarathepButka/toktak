// features/profile/presentation/bloc/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/profile/domain/entities/profile.dart';
import 'package:toktak/features/profile/domain/usecases/get_profile_usecase.dart';

part 'profile_bloc.freezed.dart';

// ─── Events ──────────────────────────────────────────────────

@freezed
sealed class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.loadProfile(String userId) = _LoadProfile;
  const factory ProfileEvent.refreshProfile(String userId) = _RefreshProfile;
}

// ─── States ──────────────────────────────────────────────────

@freezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded(Profile profile) = _Loaded;
  const factory ProfileState.error(Failure failure) = _Error;
}

// ─── BLoC ────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfileUseCase;

  ProfileBloc({required GetProfileUseCase getProfileUseCase})
      : _getProfileUseCase = getProfileUseCase,
        super(const ProfileState.initial()) {
    on<_LoadProfile>(_onLoadProfile);
    on<_RefreshProfile>(_onRefreshProfile);
  }

  Future<void> _onLoadProfile(
    _LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileState.loading());
    final result = await _getProfileUseCase(event.userId);
    result.fold(
      (failure) => emit(ProfileState.error(failure)),
      (profile) => emit(ProfileState.loaded(profile)),
    );
  }

  Future<void> _onRefreshProfile(
    _RefreshProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await _getProfileUseCase(event.userId);
    result.fold(
      (failure) {
        if (state is! _Loaded) emit(ProfileState.error(failure));
      },
      (profile) => emit(ProfileState.loaded(profile)),
    );
  }
}
