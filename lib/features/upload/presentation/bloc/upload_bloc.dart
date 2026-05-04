// features/upload/presentation/bloc/upload_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/upload/domain/entities/upload_result.dart';
import 'package:toktak/features/upload/domain/usecases/upload_video_usecase.dart';

part 'upload_bloc.freezed.dart';

// ─── Events ──────────────────────────────────────────────────

@freezed
sealed class UploadEvent with _$UploadEvent {
  const factory UploadEvent.videoPicked(File file) = _VideoPicked;
  const factory UploadEvent.captionChanged(String caption) = _CaptionChanged;
  const factory UploadEvent.submit() = _Submit;
  const factory UploadEvent.reset() = _Reset;
}

// ─── States ──────────────────────────────────────────────────

@freezed
sealed class UploadState with _$UploadState {
  const factory UploadState.initial() = _Initial;

  const factory UploadState.previewing({
    required File file,
    @Default('') String caption,
  }) = _Previewing;

  const factory UploadState.uploading({
    required File file,
    required String caption,
    @Default(0.0) double progress,
  }) = _Uploading;

  const factory UploadState.success(UploadResult result) = _Success;

  const factory UploadState.error({
    required Failure failure,
    File? file,
    String? caption,
  }) = _Error;
}

// ─── BLoC ────────────────────────────────────────────────────

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadVideoUseCase _uploadVideoUseCase;

  UploadBloc({required UploadVideoUseCase uploadVideoUseCase})
      : _uploadVideoUseCase = uploadVideoUseCase,
        super(const UploadState.initial()) {
    on<_VideoPicked>(_onVideoPicked);
    on<_CaptionChanged>(_onCaptionChanged);
    on<_Submit>(_onSubmit);
    on<_Reset>(_onReset);
  }

  void _onVideoPicked(_VideoPicked event, Emitter<UploadState> emit) {
    emit(UploadState.previewing(file: event.file));
  }

  void _onCaptionChanged(_CaptionChanged event, Emitter<UploadState> emit) {
    final current = state;
    if (current is _Previewing) {
      emit(current.copyWith(caption: event.caption));
    }
  }

  Future<void> _onSubmit(_Submit event, Emitter<UploadState> emit) async {
    final current = state;
    if (current is! _Previewing) return;

    emit(UploadState.uploading(
      file: current.file,
      caption: current.caption,
      progress: 0.0,
    ));

    final result = await _uploadVideoUseCase(
      videoFile: current.file,
      caption: current.caption,
      onProgress: (p) {
        // Emit progress updates — use add() for streaming progress
        if (!isClosed) {
          emit(UploadState.uploading(
            file: current.file,
            caption: current.caption,
            progress: p,
          ));
        }
      },
    );

    result.fold(
      (failure) => emit(UploadState.error(
        failure: failure,
        file: current.file,
        caption: current.caption,
      )),
      (uploadResult) => emit(UploadState.success(uploadResult)),
    );
  }

  void _onReset(_Reset event, Emitter<UploadState> emit) {
    emit(const UploadState.initial());
  }
}
