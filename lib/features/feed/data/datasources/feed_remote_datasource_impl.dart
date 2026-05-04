// features/feed/data/datasources/feed_remote_datasource_impl.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final ApiClient _apiClient;

  const FeedRemoteDataSourceImpl(this._apiClient);

  @override
  Future<FeedResponse> getFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.feed,
        queryParameters: {'page': page, 'limit': limit},
      );
      return FeedResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ?? 'Failed to load feed',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<VideoModel> likeVideo(String videoId) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.likeVideo(videoId));
      return VideoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ?? 'Failed to like video',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<VideoModel> unlikeVideo(String videoId) async {
    try {
      final response = await _apiClient.dio.delete(ApiEndpoints.likeVideo(videoId));
      return VideoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ?? 'Failed to unlike video',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<VideoModel> getVideoDetail(String videoId) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.videoDetail(videoId));
      return VideoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ?? 'Failed to load video',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
