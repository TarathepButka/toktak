// features/search/domain/usecases/search_videos_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/search/data/models/search_result_model.dart';
import 'package:toktak/features/search/domain/repositories/search_repository.dart';

class SearchVideosUseCase {
  final SearchRepository _repository;

  const SearchVideosUseCase(this._repository);

  Future<Either<Failure, List<SearchResultModel>>> call({String? keyword}) =>
      _repository.getSearchVideos(keyword: keyword);
}
