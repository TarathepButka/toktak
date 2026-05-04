// features/profile/data/datasources/profile_remote_datasource_impl.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:toktak/features/profile/data/models/profile_model.dart';

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  const ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final responses = await Future.wait([
        _apiClient.dio.get(ApiEndpoints.userProfile(userId)),
        _apiClient.dio.get(ApiEndpoints.userVideos(userId)),
      ]);

      final profileData = responses[0].data as Map<String, dynamic>;
      final videosData = responses[1].data as Map<String, dynamic>;
      
      final videosList = (videosData['videos'] as List<dynamic>?) ?? [];
      
      profileData['videos'] = videosList;
      
      return ProfileModel.fromJson(profileData);
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ??
            'Failed to load profile',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
