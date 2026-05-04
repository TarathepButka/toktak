// core/constants/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL — change for production
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator localhost
  static const String baseUrlIOS = 'http://localhost:8080';

  // Auth
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
  static const String authLine = '/auth/line';
  static const String authRefresh = '/auth/refresh';

  // Feed
  static const String feed = '/feed';

  // Videos
  static const String videos = '/videos';
  static String videoDetail(String id) => '/videos/$id';
  static String likeVideo(String id) => '/videos/$id/like';
  static String videoComments(String id) => '/videos/$id/comments';

  // Comments
  static String deleteComment(String id) => '/comments/$id';

  // Search
  static const String search = '/search';
  static const String searchTrending = '/search/trending';

  // Users
  static String userProfile(String id) => '/users/$id';
  static String userVideos(String id) => '/users/$id/videos';

  // Upload
  static const String uploadPresign = '/upload/presign';

  // Search with keyword
  static String searchWithKeyword(String q) => '/search?q=${Uri.encodeQueryComponent(q)}';

  // Dev
  static const String mockSeed = '/videos/mock/seed';
}
