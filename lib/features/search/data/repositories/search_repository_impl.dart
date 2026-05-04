// features/search/data/repositories/search_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/search/data/datasources/search_remote_datasource.dart';
import 'package:toktak/features/search/data/models/search_result_model.dart';
import 'package:toktak/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;

  const SearchRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<SearchResultModel>>> getSearchVideos({
    String? keyword,
  }) async {
    try {
      final results = await _remoteDataSource.getSearchVideos(keyword: keyword);
      return right(results);
    } on ServerException catch (e) {
      return left(Failure.server(message: e.message, code: e.statusCode));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
