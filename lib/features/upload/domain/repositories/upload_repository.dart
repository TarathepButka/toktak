// features/upload/domain/repositories/upload_repository.dart
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/upload/domain/entities/upload_result.dart';

abstract class UploadRepository {
  /// Uploads [videoFile] to MinIO via presigned URL, then registers
  /// the video metadata in the backend. Reports progress 0.0→1.0 via [onProgress].
  Future<Either<Failure, UploadResult>> uploadVideo({
    required File videoFile,
    required String caption,
    required void Function(double progress) onProgress,
  });
}
