// features/feed/presentation/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/feed/presentation/bloc/feed_bloc.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/presentation/widgets/video_card.dart';

class FeedPage extends StatefulWidget {
  final bool isPageVisible;
  const FeedPage({super.key, this.isPageVisible = true});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<FeedBloc>().add(const FeedEvent.loadFeed());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Following',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'For You',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            loaded:
                (videos, hasMore, currentPage, currentIndex, isLoadingMore) {
              if (videos.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FeedBloc>().add(const FeedEvent.refreshFeed());
                },
                color: AppTheme.primary,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  onPageChanged: (index) {
                    context.read<FeedBloc>().add(FeedEvent.changeVideo(index));
                  },
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoCard(
                      video: video,
                      isActive: index == currentIndex && widget.isPageVisible,
                      onLike: () {
                        context
                            .read<FeedBloc>()
                            .add(FeedEvent.likeVideo(video.id));
                      },
                      onComment: () {
                        _showCommentsBottomSheet(video);
                      },
                      onShare: () {
                        _shareVideo(video);
                      },
                    );
                  },
                ),
              );
            },
            error: (failure) => _buildError(failure),
          );
        },
      ),
    );
  }

  void _showCommentsBottomSheet(VideoModel video) {
    final comments = _mockComments(video);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${video.author?.username ?? 'unknown'}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: comments.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == comments.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Comments are mocked in this build. Hook this sheet to the backend when the comments endpoint is ready.',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, height: 1.4),
                              ),
                            );
                          }

                          final comment = comments[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.surfaceVariant,
                              backgroundImage: NetworkImage(comment.avatarUrl),
                            ),
                            title: Text(
                              comment.username,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              comment.content,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Add a comment...',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Comment composer is ready for backend wiring.')),
                            );
                          },
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _shareVideo(VideoModel video) {
    final shareText =
        '${video.caption.isNotEmpty ? video.caption : 'Check out this video'}\n${video.videoUrl}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video link copied to clipboard')),
    );
  }

  List<_MockComment> _mockComments(VideoModel video) {
    final authorName = video.author?.username ?? 'unknown';
    return [
      _MockComment(
        username: authorName,
        content: 'This one is clean. The pacing works really well.',
        avatarUrl: video.author?.avatarUrl ??
            'https://picsum.photos/seed/comment-1/100/100',
      ),
      _MockComment(
        username: 'trendwatch',
        content: 'Saved this for later. Great edit.',
        avatarUrl: 'https://picsum.photos/seed/comment-2/100/100',
      ),
      _MockComment(
        username: 'movie_fan',
        content: 'Need more clips like this in the feed.',
        avatarUrl: 'https://picsum.photos/seed/comment-3/100/100',
      ),
    ];
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('No videos yet',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                context.read<FeedBloc>().add(const FeedEvent.loadFeed()),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(dynamic failure) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to retry',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<FeedBloc>().add(const FeedEvent.loadFeed()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockComment {
  final String username;
  final String content;
  final String avatarUrl;

  const _MockComment({
    required this.username,
    required this.content,
    required this.avatarUrl,
  });
}
