// features/search/domain/repositories/search_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/search/data/models/search_result_model.dart';

/// Domain contract for the search feature.
/// Returns typed `List<SearchResultModel>` list instead of `List<dynamic>`.
abstract class SearchRepository {
  Future<Either<Failure, List<SearchResultModel>>> getSearchVideos({
    String? keyword,
  });
}
