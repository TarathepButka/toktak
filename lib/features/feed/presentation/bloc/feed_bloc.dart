// features/feed/presentation/bloc/feed_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/core/storage/local_storage_service.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/domain/repositories/feed_repository.dart';

part 'feed_bloc.freezed.dart';

// ─── Events ──────────────────────────────────────────────────

@freezed
sealed class FeedEvent with _$FeedEvent {
  const factory FeedEvent.loadFeed() = _LoadFeed;
  const factory FeedEvent.refreshFeed() = _RefreshFeed;
  const factory FeedEvent.loadMore() = _LoadMore;
  const factory FeedEvent.likeVideo(String videoId) = _LikeVideo;
  const factory FeedEvent.changeVideo(int index) = _ChangeVideo;
}

// ─── States ──────────────────────────────────────────────────

@freezed
sealed class FeedState with _$FeedState {
  const factory FeedState.initial() = _Initial;
  const factory FeedState.loading() = _Loading;
  const factory FeedState.loaded({
    required List<VideoModel> videos,
    required bool hasMore,
    @Default(1) int currentPage,
    @Default(0) int currentIndex,
    @Default(false) bool isLoadingMore,
  }) = FeedLoaded;
  const factory FeedState.error(Failure failure) = _Error;
}

// ─── BLoC ────────────────────────────────────────────────────

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepository;
  final LocalStorageService _storage;

  FeedBloc({
    required FeedRepository feedRepository,
    required LocalStorageService storage,
  })  : _feedRepository = feedRepository,
        _storage = storage,
        super(const FeedState.initial()) {
    on<_LoadFeed>(_onLoadFeed);
    on<_RefreshFeed>(_onRefreshFeed);
    on<_LoadMore>(_onLoadMore);
    on<_LikeVideo>(_onLikeVideo);
    on<_ChangeVideo>(_onChangeVideo);
  }

  Future<void> _onLoadFeed(_LoadFeed event, Emitter<FeedState> emit) async {
    emit(const FeedState.loading());
    final result = await _feedRepository.getFeed(page: 1);
    result.fold(
      (failure) => emit(FeedState.error(failure)),
      (response) => emit(FeedState.loaded(
        videos: response.videos,
        hasMore: response.hasMore,
        currentPage: 1,
      )),
    );
  }

  Future<void> _onRefreshFeed(_RefreshFeed event, Emitter<FeedState> emit) async {
    final result = await _feedRepository.getFeed(page: 1);
    result.fold(
      (failure) {
        // Keep current state on refresh failure
        if (state is! FeedLoaded) {
          emit(FeedState.error(failure));
        }
      },
      (response) => emit(FeedState.loaded(
        videos: response.videos,
        hasMore: response.hasMore,
        currentPage: 1,
      )),
    );
  }

  Future<void> _onLoadMore(_LoadMore event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is! FeedLoaded || !currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await _feedRepository.getFeed(page: nextPage);

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (response) => emit(FeedState.loaded(
        videos: [...currentState.videos, ...response.videos],
        hasMore: response.hasMore,
        currentPage: nextPage,
        currentIndex: currentState.currentIndex,
      )),
    );
  }

  // ─── UI-First Optimistic Like ──────────────────────────────

  Future<void> _onLikeVideo(_LikeVideo event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Find the video
    final videoIndex = currentState.videos.indexWhere((v) => v.id == event.videoId);
    if (videoIndex == -1) return;

    final video = currentState.videos[videoIndex];
    final wasLiked = video.isLiked;

    // 1️⃣ OPTIMISTIC: Update UI immediately
    final updatedVideo = video.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? video.likesCount - 1 : video.likesCount + 1,
    );

    final updatedVideos = List<VideoModel>.from(currentState.videos);
    updatedVideos[videoIndex] = updatedVideo;

    emit(currentState.copyWith(videos: updatedVideos));

    // 2️⃣ Save to local storage
    await _storage.queueLikeAction(event.videoId, !wasLiked);

    // 3️⃣ SYNC: Call backend
    final result = wasLiked
        ? await _feedRepository.unlikeVideo(event.videoId)
        : await _feedRepository.likeVideo(event.videoId);

    result.fold(
      (failure) {
        // 4️⃣ ROLLBACK on failure
        final rollbackVideos = List<VideoModel>.from(currentState.videos);
        // Restore original video
        final freshState = state;
        if (freshState is FeedLoaded) {
          rollbackVideos[videoIndex] = video;
          emit(freshState.copyWith(videos: rollbackVideos));
        }
      },
      (_) {
        // Success — UI already updated, clear from queue
      },
    );
  }

  void _onChangeVideo(_ChangeVideo event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;
    emit(currentState.copyWith(currentIndex: event.index));

    // Auto-load more when near the end
    if (event.index >= currentState.videos.length - 3 && currentState.hasMore) {
      add(const FeedEvent.loadMore());
    }
  }
}
