// features/upload/data/datasources/upload_remote_datasource_impl.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/features/upload/data/datasources/upload_remote_datasource.dart';

class UploadRemoteDataSourceImpl implements UploadRemoteDataSource {
  final ApiClient _apiClient;

  const UploadRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String caption,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final filename = videoFile.path.split(RegExp(r'[/\\]')).last;
      final contentType = lookupMimeType(videoFile.path) ?? 'video/mp4';

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
        'caption': caption,
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.videos,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ??
            e.error?.toString() ??
            e.message ??
            'Upload failed',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }
}
