// features/search/domain/entities/search_result.dart

/// Pure domain entity representing a single search result video.
class SearchResult {
  final String id;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int viewsCount;
  final int likesCount;
  final DateTime? createdAt;
  final SearchResultAuthor? author;

  const SearchResult({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.caption = '',
    this.viewsCount = 0,
    this.likesCount = 0,
    this.createdAt,
    this.author,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SearchResult && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class SearchResultAuthor {
  final String id;
  final String username;
  final String? avatarUrl;

  const SearchResultAuthor({
    required this.id,
    required this.username,
    this.avatarUrl,
  });
}
