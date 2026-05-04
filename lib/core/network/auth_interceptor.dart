// core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/storage/local_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final LocalStorageService _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.getAuthToken();
    // Only add token if not already present (allows skipping by setting empty string)
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            ApiEndpoints.authRefresh,
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Authorization': ''}), // No auth header for refresh
          );

          final newToken = response.data['access_token'] as String;
          final newRefreshToken = response.data['refresh_token'] as String;

          await _storage.saveAuthToken(newToken);
          await _storage.saveRefreshToken(newRefreshToken);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh failed — clear tokens and let error propagate
          await _storage.clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
