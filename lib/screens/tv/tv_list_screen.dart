import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/tv_bloc/tv_bloc.dart';
import '../../bloc/tv_bloc/tv_event.dart';
import '../../bloc/tv_bloc/tv_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/tv_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/movie_filter.dart';
import '../../data/services/tv_service.dart';

class TvListScreen extends StatefulWidget {
  final String category;
  const TvListScreen({super.key, required this.category});

  @override
  State<TvListScreen> createState() => _TvListScreenState();
}

class _TvListScreenState extends State<TvListScreen> {
  final _scrollCtrl = ScrollController();

  // Genre filter chips — loaded from /genre/tv/list (TV genre IDs differ from movie)
  List<GenreModel> _genres        = [];
  int?             _selectedGenreId;

  // Sort option — genre pages only
  MovieSortOption _sortOption = MovieSortOption.popular;

  // ── Pagination state (owned by the screen) ────────────────────────
  List<TvModel> _shows        = [];
  int           _currentPage  = 1;
  bool          _isLoadingMore = false;
  bool          _hasMore       = true;
  bool          _isFirstLoad   = true;
  String?       _loadError;

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
    if (!widget.category.startsWith('genre_')) _loadGenres();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────

  Future<void> _loadGenres() async {
    try {
      // TV genres come from /genre/tv/list — IDs are different from movie genres.
      final genres = await TvService().getGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {}
  }

  void _fetchPage(int page) {
    context.read<TvBloc>().add(TvFetchListPage(
      category:   widget.category,
      page:       page,
      sortOption: _sortOption,
    ));
  }

  // ── Scroll → load next page ────────────────────────────────────────

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      setState(() => _isLoadingMore = true);
      _fetchPage(_currentPage + 1);
    }
  }

  // ── Sort (genre pages only) ────────────────────────────────────────

  Future<void> _showSortSheet() async {
    final result = await showModalBottomSheet<MovieSortOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TvSortSheet(current: _sortOption),
    );
    if (result != null && mounted) {
      setState(() {
        _sortOption      = result;
        _shows           = [];
        _currentPage     = 1;
        _isLoadingMore   = false;
        _hasMore         = true;
        _isFirstLoad     = true;
        _loadError       = null;
        _selectedGenreId = null;
      });
      _fetchPage(1);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String get _title {
    if (widget.category.startsWith('genre_')) {
      // Genre name lookup — TV genre IDs are different from movie genre IDs.
      // Full names are loaded from _genres; use genreId as fallback.
      final genreId = int.parse(widget.category.split('_')[1]);
      final match = _genres.where((g) => g.id == genreId).toList();
      return match.isNotEmpty ? match.first.name : 'TV Genre';
    }
    switch (widget.category) {
      case 'popular':      return 'Popular';
      case 'airing_today': return 'Airing Today';
      case 'on_the_air':   return 'On The Air';
      case 'top_rated':    return 'Top Rated';
      default:             return 'TV Shows';
    }
  }

  List<TvModel> _filterByGenre(List<TvModel> shows) {
    if (_selectedGenreId == null) return shows;
    return shows.where((s) => s.genreIds.contains(_selectedGenreId)).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filterByGenre(_shows);

    return BlocListener<TvBloc, TvState>(
      listenWhen: (_, s) => s is TvListLoaded || s is TvError,
      listener: (_, state) {
        if (state is TvListLoaded) {
          setState(() {
            // Page 1 → replace; page 2+ → append
            _shows = state.page == 1
                ? state.shows
                : [..._shows, ...state.shows];
            _currentPage   = state.page;
            _hasMore       = state.hasMore;
            _isLoadingMore = false;
            _isFirstLoad   = false;
            _loadError     = null;
          });
        } else if (state is TvError) {
          setState(() {
            _isLoadingMore = false;
            _isFirstLoad   = false;
            if (_shows.isEmpty) _loadError = state.message;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_title),
          actions: [
            if (widget.category.startsWith('genre_'))
              IconButton(
                tooltip: 'Sort',
                icon: Icon(
                  Icons.sort_rounded,
                  color: _sortOption != MovieSortOption.popular
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                onPressed: _showSortSheet,
              ),
          ],
        ),
        body: Column(
          children: [
            // ── ACTIVE SORT CHIP ─────────────────────────────────
            if (widget.category.startsWith('genre_') &&
                _sortOption != MovieSortOption.popular)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm, 4, AppSpacing.xs4, 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortOption.label,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _sortOption    = MovieSortOption.popular;
                                _shows         = [];
                                _currentPage   = 1;
                                _isLoadingMore = false;
                                _hasMore       = true;
                                _isFirstLoad   = true;
                                _loadError     = null;
                              });
                              _fetchPage(1);
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── GENRE FILTER CHIPS (category pages only) ─────────
            if (_genres.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: _genres.length + 1,
                  itemBuilder: (context, i) {
                    final isAll    = i == 0;
                    final genre    = isAll ? null : _genres[i - 1];
                    final isSelected = isAll
                        ? _selectedGenreId == null
                        : _selectedGenreId == genre?.id;

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedGenreId = genre?.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          isAll ? 'All' : genre!.name,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── CONTENT ──────────────────────────────────────────
            Expanded(child: _buildContent(filtered)),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────

  Widget _buildContent(List<TvModel> filtered) {
    if (_isFirstLoad) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_loadError != null && _shows.isEmpty) {
      return Center(
        child: Text(
          _loadError!,
          style: AppTypography.body1.copyWith(color: AppColors.error),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No TV shows',
          style: AppTypography.body1.copyWith(color: AppColors.textTertiary),
        ),
      );
    }
    return _buildGrid(filtered);
  }

  // ── Grid ───────────────────────────────────────────────────────────

  Widget _buildGrid(List<TvModel> shows) {
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildShowCard(shows[i]),
              childCount: shows.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.65,
            ),
          ),
        ),

        // ── LOADING MORE ─────────────────────────────────────────
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

        // ── END OF LIST ──────────────────────────────────────────
        if (!_hasMore && !_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'All shows loaded',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textDisabled),
                ),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ),
      ],
    );
  }

  Widget _buildShowCard(TvModel show) {
    return GestureDetector(
      onTap: () => context.push(
        AppRouter.tvDetail,
        extra: {
          'id':           show.id,
          'name':         show.name,
          'overview':     show.overview,
          'posterUrl':    show.fullPosterUrl,
          'backdropUrl':  show.fullBackdropUrl,
          'rating':       show.voteAverage,
          'firstAirDate': show.firstAirDate,
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: show.fullPosterUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, _) =>
                        Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
                // "TV" badge — distinguishes from movie cards in mixed context
                Positioned(
                  top: AppSpacing.xs4,
                  left: AppSpacing.xs4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent2.withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      'TV',
                      style: AppTypography.overline.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            show.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.accent1, size: 12),
              const SizedBox(width: 2),
              Text(
                show.voteAverage.toStringAsFixed(1),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              if (show.releaseYear.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs4),
                Text(
                  show.releaseYear,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── TV SORT SHEET ──────────────────────────────────────────────────
// Excludes [MovieSortOption.longest] — TV shows have no runtime sort
// on TMDB Discover. All other options map cleanly to TV endpoints.
class _TvSortSheet extends StatelessWidget {
  final MovieSortOption current;
  const _TvSortSheet({required this.current});

  // 'longest' excluded — TvService falls back to popularity.desc anyway,
  // and surfacing a non-functional option would confuse users.
  static const _options = [
    MovieSortOption.popular,
    MovieSortOption.topRated,
    MovieSortOption.latest,
    MovieSortOption.trending,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── DRAG HANDLE ────────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── HEADER ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.xs, 0,
            ),
            child: Row(
              children: [
                Text('Sort by', style: AppTypography.subtitle1),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // ── SORT OPTIONS ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: _options.map((opt) {
                final isSelected = current == opt;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, opt),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDisabled,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          opt.label,
                          style: AppTypography.body1.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
          ),
        ],
      ),
    );
  }
}
