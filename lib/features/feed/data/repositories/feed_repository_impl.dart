// features/feed/data/repositories/feed_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/core/storage/local_storage_service.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storage;

  FeedRepositoryImpl({
    required ApiClient apiClient,
    required LocalStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  @override
  Future<Either<Failure, FeedResponse>> getFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.feed,
        queryParameters: {'page': page, 'limit': limit},
      );

      final feedResponse = FeedResponse.fromJson(response.data);

      // Cache first page locally
      if (page == 1) {
        await _storage.cacheFeedMeta(
          feedResponse.videos.map((v) => v.toJson()).toList(),
        );
      }

      return right(feedResponse);
    } on DioException catch (e) {
      // Fallback to cached data on network error
      if (page == 1) {
        final cached = _storage.getCachedFeed();
        if (cached != null && cached.isNotEmpty) {
          return right(FeedResponse(
            videos: cached.map((v) => VideoModel.fromJson(v)).toList(),
            hasMore: false,
            page: 1,
          ));
        }
      }
      return left(Failure.server(
        message: e.response?.data?['message'] ?? 'Failed to load feed',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoModel>> likeVideo(String videoId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.likeVideo(videoId),
      );
      return right(VideoModel.fromJson(response.data));
    } on DioException catch (e) {
      return left(Failure.server(
        message: e.response?.data?['message'] ?? 'Failed to like video',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoModel>> unlikeVideo(String videoId) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.likeVideo(videoId),
      );
      return right(VideoModel.fromJson(response.data));
    } on DioException catch (e) {
      return left(Failure.server(
        message: e.response?.data?['message'] ?? 'Failed to unlike video',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoModel>> getVideoDetail(String videoId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.videoDetail(videoId),
      );
      return right(VideoModel.fromJson(response.data));
    } on DioException catch (e) {
      return left(Failure.server(
        message: e.response?.data?['message'] ?? 'Failed to load video',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
