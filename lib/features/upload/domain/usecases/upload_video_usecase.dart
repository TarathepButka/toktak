// features/upload/domain/usecases/upload_video_usecase.dart
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/upload/domain/entities/upload_result.dart';
import 'package:toktak/features/upload/domain/repositories/upload_repository.dart';

class UploadVideoUseCase {
  final UploadRepository _repository;

  const UploadVideoUseCase(this._repository);

  Future<Either<Failure, UploadResult>> call({
    required File videoFile,
    required String caption,
    required void Function(double progress) onProgress,
  }) =>
      _repository.uploadVideo(
        videoFile: videoFile,
        caption: caption,
        onProgress: onProgress,
      );
}
