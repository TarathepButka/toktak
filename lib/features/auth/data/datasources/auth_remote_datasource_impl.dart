// features/auth/data/datasources/auth_remote_datasource_impl.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.authGoogle,
        data: {'id_token': idToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            (e.response?.data as Map?)?['message'] as String? ?? 'Server error',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<AuthResponse> loginWithLine(String accessToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.authLine,
        data: {'access_token': accessToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            (e.response?.data as Map?)?['message'] as String? ?? 'Server error',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw AuthException(message: 'LINE login failed: $e');
    }
  }
}
