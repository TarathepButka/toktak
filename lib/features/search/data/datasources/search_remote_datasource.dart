// features/search/data/datasources/search_remote_datasource.dart
import 'package:toktak/features/search/data/models/search_result_model.dart';

/// Contract for all remote search operations.
abstract class SearchRemoteDataSource {
  /// Fetches the current trending / discovery feed for the search grid.
  Future<List<SearchResultModel>> getSearchVideos({String? keyword});
}
