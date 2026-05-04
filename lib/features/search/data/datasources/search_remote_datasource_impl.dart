// features/search/data/datasources/search_remote_datasource_impl.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/features/search/data/datasources/search_remote_datasource.dart';
import 'package:toktak/features/search/data/models/search_result_model.dart';

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient _apiClient;

  const SearchRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SearchResultModel>> getSearchVideos({String? keyword}) async {
    try {
      final queryParams = <String, dynamic>{'limit': 40};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['q'] = keyword;
      }

      final response = await _apiClient.dio.get(
        '/search',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];

      return results
          .cast<Map<String, dynamic>>()
          .map(SearchResultModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: (e.response?.data as Map?)?['message'] as String? ??
            'Search failed',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
