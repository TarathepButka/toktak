// features/search/presentation/pages/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/injection.dart';
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
  late final SearchBloc _searchBloc;

  int _activeIndex = 0;
  final double _stepSize = 60.0;
  int _currentVideoCount = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchBloc = getIt<SearchBloc>()..add(const SearchEvent.load());
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final keyword = _searchController.text.trim();
      if (keyword.isEmpty) {
        _searchBloc.add(const SearchEvent.load());
      } else {
        _searchBloc.add(SearchEvent.search(keyword));
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Header approximate height (tags list + padding)
    const headerHeight = 60.0;

    double adjustedOffset = _scrollController.offset - headerHeight;
    if (adjustedOffset < 0) adjustedOffset = 0;

    // Divide scroll offset into steps to determine active video
    int newIndex = (adjustedOffset / _stepSize).floor();

    // Clamp to valid range
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
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
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
        body: CustomScrollView(
          controller: _scrollController,
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
                    loaded: (videos) => SliverGrid(
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
                            isActive: i == _activeIndex && widget.isPageVisible,
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
                    ),
                    error: (failure) => SliverToBoxAdapter(
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
