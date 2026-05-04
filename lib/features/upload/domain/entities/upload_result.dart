// features/upload/domain/entities/upload_result.dart

/// Pure domain entity representing a successfully uploaded video.
class UploadResult {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;

  const UploadResult({
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
  });
}
