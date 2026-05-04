// features/upload/data/repositories/upload_repository_impl.dart
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/upload/data/datasources/upload_remote_datasource.dart';
import 'package:toktak/features/upload/domain/entities/upload_result.dart';
import 'package:toktak/features/upload/domain/repositories/upload_repository.dart';

class UploadRepositoryImpl implements UploadRepository {
  final UploadRemoteDataSource _dataSource;

  const UploadRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, UploadResult>> uploadVideo({
    required File videoFile,
    required String caption,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final videoData = await _dataSource.uploadVideo(
        videoFile: videoFile,
        caption: caption,
        onProgress: onProgress,
      );

      return right(UploadResult(
        videoId: videoData['id'] as String? ?? '',
        videoUrl: videoData['video_url'] as String? ?? '',
        thumbnailUrl: videoData['thumbnail_url'] as String? ?? '',
        caption: caption,
      ));
    } on ServerException catch (e) {
      return left(Failure.server(message: e.message, code: e.statusCode));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
