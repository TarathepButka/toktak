// features/feed/presentation/widgets/video_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const VideoCard({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showPlayButton = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (widget.isActive) {
        _controller!.play();
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _showPlayButton = true);
    } else {
      _controller!.play();
      setState(() => _showPlayButton = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Thumbnail ─────────────────
          if (_isInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppTheme.surfaceDark),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surfaceDark,
                child: const Center(
                    child: Icon(Icons.error_outline,
                        color: AppTheme.textMuted, size: 48)),
              ),
            ),

          // ─── Play button overlay ──────────────
          if (_showPlayButton)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ),

          // ─── Bottom gradient ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Video Info (bottom-left) ─────────
          Positioned(
            left: 16,
            bottom: 24,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.surfaceVariant,
                      backgroundImage: widget.video.author?.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              widget.video.author!.avatarUrl!)
                          : null,
                      child: widget.video.author?.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 18, color: AppTheme.textMuted)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${widget.video.author?.username ?? 'unknown'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                if (widget.video.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.video.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          // ─── Action Buttons (right side) ──────
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: widget.video.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: _formatCount(widget.video.likesCount),
                  color: widget.video.isLiked ? AppTheme.primary : Colors.white,
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(widget.video.commentsCount),
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),

          // ─── Progress indicator ───────────────
          if (_isInitialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
