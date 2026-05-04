// features/upload/data/datasources/upload_remote_datasource.dart
import 'dart:io';

abstract class UploadRemoteDataSource {
  /// Uploads [videoFile] directly to backend as multipart/form-data.
  /// Backend handles the MinIO transfer (avoids presigned URL host issues).
  /// Reports progress 0.0→1.0 via [onProgress].
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String caption,
    required void Function(double progress) onProgress,
  });
}
