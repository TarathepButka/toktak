import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toktak/core/utils/video_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/feed/domain/entities/video.dart';

/// A shared widget for displaying a video preview in a grid (Search, Profile, etc.)
/// Handles video player initialization, disposal, and auto-play logic.
class VideoGridTile extends StatefulWidget {
  final Video video;
  final bool isActive;
  final VoidCallback? onTap;

  const VideoGridTile({
    super.key,
    required this.video,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<VideoGridTile> createState() => _VideoGridTileState();
}

class _VideoGridTileState extends State<VideoGridTile> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _loadingVideoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant VideoGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeVideo();
    }
  }

  void _initializeVideo() {
    if (_controller != null) return;

    final videoUrl = widget.video.videoUrl;
    _loadingVideoUrl = videoUrl;

    VideoCacheManager.getFile(videoUrl).then((videoFile) async {
      if (!mounted || _loadingVideoUrl != videoUrl) {
        return;
      }

      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      if (!mounted || _loadingVideoUrl != videoUrl) {
        controller.dispose();
        return;
      }

      controller.setLooping(true);
      controller.setVolume(0); // Mute for grid preview

      if (mounted && widget.isActive) {
        controller.play();
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    }).catchError((error) {
      debugPrint("Video Preview Error: $error");
    });
  }

  void _disposeVideo() {
    _loadingVideoUrl = null;
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          border: widget.isActive
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (widget.video.thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.video.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white24, strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white24,
                ),
              ),

            // Video Player
            if (widget.isActive && _isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0
                        ? _controller!.value.size.width
                        : 1,
                    height: _controller!.value.size.height > 0
                        ? _controller!.value.size.height
                        : 1,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // Loading indicator while active but not yet initialized
            if (widget.isActive && !_isInitialized)
              const Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),

            // Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.black45,
                      Colors.transparent
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.video.caption.isNotEmpty)
                      Text(
                        widget.video.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow_outlined,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.video.viewsCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (widget.video.author != null)
                          Text(
                            '@${widget.video.author!.username}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
