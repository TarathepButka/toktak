// features/search/data/models/search_result_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_model.freezed.dart';
part 'search_result_model.g.dart';

@freezed
class SearchResultModel with _$SearchResultModel {
  const factory SearchResultModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'video_url') required String videoUrl,
    @JsonKey(name: 'thumbnail_url') required String thumbnailUrl,
    @Default('') String caption,
    @JsonKey(name: 'views_count') @Default(0) int viewsCount,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    SearchResultAuthorModel? author,
  }) = _SearchResultModel;

  factory SearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResultModelFromJson(json);
}

@freezed
class SearchResultAuthorModel with _$SearchResultAuthorModel {
  const factory SearchResultAuthorModel({
    required String id,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _SearchResultAuthorModel;

  factory SearchResultAuthorModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResultAuthorModelFromJson(json);
}
