// features/search/presentation/bloc/search_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/search/data/models/search_result_model.dart';
import 'package:toktak/features/search/domain/repositories/search_repository.dart';

part 'search_bloc.freezed.dart';

// ─── Events ──────────────────────────────────────────────────

@freezed
sealed class SearchEvent with _$SearchEvent {
  const factory SearchEvent.load() = _Load;
  const factory SearchEvent.search(String keyword) = _Search;
}

// ─── States ──────────────────────────────────────────────────

@freezed
sealed class SearchState with _$SearchState {
  const factory SearchState.initial() = _Initial;
  const factory SearchState.loading() = _Loading;
  const factory SearchState.loaded(List<SearchResultModel> videos) = _Loaded;
  const factory SearchState.error(Failure failure) = _Error;
}

// ─── BLoC ────────────────────────────────────────────────────

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository;

  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const SearchState.initial()) {
    on<_Load>(_onLoad);
    on<_Search>(_onSearch);
  }

  Future<void> _onLoad(_Load event, Emitter<SearchState> emit) async {
    emit(const SearchState.loading());
    final result = await _repository.getSearchVideos();
    result.fold(
      (failure) => emit(SearchState.error(failure)),
      (videos) => emit(SearchState.loaded(videos)),
    );
  }

  Future<void> _onSearch(_Search event, Emitter<SearchState> emit) async {
    emit(const SearchState.loading());
    final result = await _repository.getSearchVideos(keyword: event.keyword);
    result.fold(
      (failure) => emit(SearchState.error(failure)),
      (videos) => emit(SearchState.loaded(videos)),
    );
  }
}
