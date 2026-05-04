// features/search/presentation/pages/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/core/widgets/video_grid_tile.dart';
import 'package:toktak/features/feed/domain/entities/video.dart';
import 'package:toktak/features/search/presentation/bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  final bool isPageVisible;
  const SearchPage({super.key, this.isPageVisible = true});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  int _activeIndex = 0;
  final double _stepSize = 60.0;
  int _currentVideoCount = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _refreshSearchResults() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      context.read<SearchBloc>().add(const SearchEvent.load());
    } else {
      context.read<SearchBloc>().add(SearchEvent.search(keyword));
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _refreshSearchResults();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Header approximate height
    const headerHeight = 60.0;

    double adjustedOffset = _scrollController.offset - headerHeight;
    if (adjustedOffset < 0) adjustedOffset = 0;

    int newIndex = (adjustedOffset / _stepSize).floor();

    if (newIndex < 0) newIndex = 0;
    if (_currentVideoCount > 0 && newIndex >= _currentVideoCount) {
      newIndex = _currentVideoCount - 1;
    }

    if (_activeIndex != newIndex) {
      setState(() {
        _activeIndex = newIndex;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Search videos, users...',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 15),
              prefixIcon:
                  Icon(Icons.search, color: AppTheme.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              filled: false,
            ),
          ),
        ),
        toolbarHeight: 64,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshSearchResults();
          // Wait for the next state to be loaded or error
          await context.read<SearchBloc>().stream.firstWhere((state) =>
              state.maybeMap(
                  loaded: (_) => true,
                  error: (_) => true,
                  orElse: () => false));
        },
        color: AppTheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: BlocConsumer<SearchBloc, SearchState>(
                listener: (context, state) {
                  state.maybeWhen(
                    loaded: (videos) => setState(() {
                      _currentVideoCount = videos.length;
                    }),
                    orElse: () {},
                  );
                },
                builder: (context, state) {
                  return state.when(
                    initial: () =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                    loaded: (videos) {
                      if (videos.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text('No results found',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                        );
                      }
                      return SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 9 / 16,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final v = videos[i];
                            return VideoGridTile(
                              isActive:
                                  i == _activeIndex && widget.isPageVisible,
                              video: Video(
                                id: v.id,
                                userId: v.userId,
                                videoUrl: v.videoUrl,
                                thumbnailUrl: v.thumbnailUrl,
                                caption: v.caption,
                                viewsCount: v.viewsCount,
                                likesCount: v.likesCount,
                                createdAt: v.createdAt,
                                author: v.author != null
                                    ? VideoAuthor(
                                        id: v.author!.id,
                                        username: v.author!.username,
                                      )
                                    : null,
                              ),
                              onTap: () {
                                setState(() {
                                  _activeIndex = (_activeIndex == i) ? -1 : i;
                                });
                              },
                            );
                          },
                          childCount: videos.length,
                        ),
                      );
                    },
                    error: (failure) => SliverFillRemaining(
                      child: Center(
                        child: Text(
                          failure.when(
                            server: (msg, _) => msg,
                            network: (msg) => msg,
                            cache: (msg) => msg,
                            auth: (msg) => msg,
                            unknown: (msg) => msg,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
