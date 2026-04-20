import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../bloc/movie_bloc/movie_bloc.dart';
import '../../../bloc/movie_bloc/movie_event.dart';
import '../../../bloc/movie_bloc/movie_state.dart';
import '../../../bloc/tv_bloc/tv_bloc.dart';
import '../../../bloc/tv_bloc/tv_event.dart';
import '../../../bloc/tv_bloc/tv_state.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/tv_model.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/movie_filter.dart';
import '../../../data/services/movie_service.dart';
import '../../../data/services/tv_service.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();
  bool _hasQuery      = false;
  bool _pendingSearch = false;
  Timer? _debounce;

  // ── Media type toggle ─────────────────────────────────────────────────────
  bool _isMovieMode = true;

  // ── Per-mode filter state ─────────────────────────────────────────────────
  // Each mode preserves its own filters independently.
  MovieFilter _movieFilter = const MovieFilter();
  MovieFilter _tvFilter    = const MovieFilter();

  // ── Per-mode genre lists ──────────────────────────────────────────────────
  List<GenreModel> _movieGenres = [];
  List<GenreModel> _tvGenres    = [];

  // ── Convenience getters ───────────────────────────────────────────────────
  MovieFilter get _activeFilter => _isMovieMode ? _movieFilter : _tvFilter;

  bool get _hasActiveFilter => !_activeFilter.isDefault;

  int get _filterBadgeCount =>
      _activeFilter.genreIds.length +
      (_activeFilter.sortBy != MovieSortOption.popular ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _loadGenres();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  /// Loads movie and TV genres in parallel. Each is stored separately so the
  /// filter sheet shows the correct genre list for the active media type.
  Future<void> _loadGenres() async {
    final fMovie = MovieService().getGenres().catchError((_) => <GenreModel>[]);
    final fTv    = TvService().getGenres().catchError((_) => <GenreModel>[]);
    final results = await Future.wait([fMovie, fTv]);
    if (!mounted) return;
    setState(() {
      _movieGenres = results[0];
      _tvGenres    = results[1];
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── MODE SWITCH ───────────────────────────────────────────────────────────

  void _onModeSwitch(bool isMovie) {
    if (_isMovieMode == isMovie) return;
    _debounce?.cancel();
    _searchCtrl.clear();
    // Clear search state for the mode we're leaving
    if (_isMovieMode) {
      context.read<MovieBloc>().add(MovieClearSearch());
    } else {
      context.read<TvBloc>().add(TvClearSearch());
    }
    setState(() {
      _isMovieMode    = isMovie;
      _hasQuery       = false;
      _pendingSearch  = false;
    });
    _focusNode.requestFocus();
  }

  // ── SEARCH LOGIC ──────────────────────────────────────────────────────────

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      if (_hasActiveFilter) {
        setState(() { _hasQuery = false; _pendingSearch = true; });
        if (_isMovieMode) {
          context.read<MovieBloc>().add(MovieDiscover(_movieFilter));
        } else {
          context.read<TvBloc>().add(TvDiscover(_tvFilter));
        }
      } else {
        setState(() { _hasQuery = false; _pendingSearch = false; });
        if (_isMovieMode) {
          context.read<MovieBloc>().add(MovieClearSearch());
        } else {
          context.read<TvBloc>().add(TvClearSearch());
        }
      }
      return;
    }
    setState(() { _hasQuery = true; _pendingSearch = true; });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (_isMovieMode) {
        context.read<MovieBloc>().add(MovieSearch(trimmed));
      } else {
        context.read<TvBloc>().add(TvSearch(trimmed));
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearch('');
    _focusNode.requestFocus();
  }

  // ── FILTER LOGIC ──────────────────────────────────────────────────────────

  void _onFilterChanged(MovieFilter newFilter) {
    final query = _searchCtrl.text.trim();
    if (_isMovieMode) {
      if (query.isNotEmpty) {
        setState(() { _movieFilter = newFilter; _pendingSearch = true; });
        _debounce?.cancel();
        context.read<MovieBloc>().add(MovieSearch(query));
      } else if (!newFilter.isDefault) {
        setState(() { _movieFilter = newFilter; _pendingSearch = true; });
        context.read<MovieBloc>().add(MovieDiscover(newFilter));
      } else {
        setState(() { _movieFilter = newFilter; _hasQuery = false; _pendingSearch = false; });
        context.read<MovieBloc>().add(MovieClearSearch());
      }
    } else {
      if (query.isNotEmpty) {
        setState(() { _tvFilter = newFilter; _pendingSearch = true; });
        _debounce?.cancel();
        context.read<TvBloc>().add(TvSearch(query));
      } else if (!newFilter.isDefault) {
        setState(() { _tvFilter = newFilter; _pendingSearch = true; });
        context.read<TvBloc>().add(TvDiscover(newFilter));
      } else {
        setState(() { _tvFilter = newFilter; _hasQuery = false; _pendingSearch = false; });
        context.read<TvBloc>().add(TvClearSearch());
      }
    }
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<MovieFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialFilter: _activeFilter,
        genres:     _isMovieMode ? _movieGenres : _tvGenres,
        hasKeyword: _hasQuery,
        isTV:       !_isMovieMode,
      ),
    );
    if (result != null && mounted) _onFilterChanged(result);
  }

  // ── CLIENT-SIDE GENRE FILTER ──────────────────────────────────────────────
  // Applied when the server endpoint can't handle genre filtering
  // (keyword search & trending). OR logic: match any selected genre.

  List<MovieModel> _applyClientMovieGenreFilter(List<MovieModel> movies) {
    if (_movieFilter.genreIds.isEmpty) return movies;
    return movies
        .where((m) => _movieFilter.genreIds.any((id) => m.genreIds.contains(id)))
        .toList();
  }

  List<TvModel> _applyClientTvGenreFilter(List<TvModel> shows) {
    if (_tvFilter.genreIds.isEmpty) return shows;
    return shows
        .where((s) => _tvFilter.genreIds.any((id) => s.genreIds.contains(id)))
        .toList();
  }

  // ── RESULTS LABEL ─────────────────────────────────────────────────────────

  String _buildResultsLabel(int count) {
    final filter = _activeFilter;
    final parts = <String>['$count results'];
    if (filter.sortBy != MovieSortOption.popular) parts.add(filter.sortBy.label);
    if (filter.genreNames.isNotEmpty) parts.add(filter.genreNames.join(', '));
    return parts.join(' · ');
  }

  Widget _buildSectionDivider(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──────────────────────────────────────────────
            Padding(
              padding: AppSpacing.hPad.copyWith(top: AppSpacing.pageTopPadding),
              child: Text('Search', style: AppTypography.heading2),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── MEDIA TYPE TOGGLE ─────────────────────────────────
            _buildModeToggle(),
            const SizedBox(height: AppSpacing.sm),

            // ── SEARCH BAR + FILTER BUTTON ────────────────────────
            Padding(
              padding: AppSpacing.hPad,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      style: AppTypography.body1
                          .copyWith(color: AppColors.textPrimary),
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: _isMovieMode
                            ? 'Search title, actor...'
                            : 'Search show title, actor...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _hasQuery
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textTertiary,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.searchRadius,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.searchRadius,
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.searchRadius,
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),

                  // Filter button — tinted red when any filter is active
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _hasActiveFilter
                                ? AppColors.primary
                                : AppColors.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: _hasActiveFilter
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _hasActiveFilter
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_filterBadgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: AppColors.accent1,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_filterBadgeCount',
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── ACTIVE FILTER CHIPS ───────────────────────────────
            if (_hasActiveFilter) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.hPad,
                  children: [
                    if (_activeFilter.sortBy != MovieSortOption.popular)
                      _ActiveFilterChip(
                        label: _activeFilter.sortBy.label,
                        onRemove: () => _onFilterChanged(
                          _activeFilter.copyWith(
                            sortBy: MovieSortOption.popular,
                          ),
                        ),
                      ),
                    ..._activeFilter.genreNames.asMap().entries.map((e) =>
                      _ActiveFilterChip(
                        label: e.value,
                        onRemove: () {
                          final ids   = List<int>.from(_activeFilter.genreIds)
                              ..removeAt(e.key);
                          final names = List<String>.from(
                              _activeFilter.genreNames)
                              ..removeAt(e.key);
                          _onFilterChanged(_activeFilter.copyWith(
                            genreIds: ids, genreNames: names,
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── SORT-KEYWORD WARNING ──────────────────────────────
            if (_hasQuery && _activeFilter.sortBy != MovieSortOption.popular)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: AppSpacing.xs4),
                    Text(
                      "Sort doesn't apply when searching by keyword",
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // ── RESULTS AREA — switches BLoC type based on mode ───
            Expanded(
              child: _isMovieMode
                  ? BlocConsumer<MovieBloc, MovieState>(
                      key: const ValueKey('movie-search'),
                      buildWhen: (_, curr) =>
                          curr is MovieInitial ||
                          curr is MovieLoading ||
                          curr is MovieSearchLoaded ||
                          curr is MovieDiscoverLoaded ||
                          curr is MovieError,
                      listenWhen: (_, curr) =>
                          curr is MovieSearchLoaded ||
                          curr is MovieDiscoverLoaded ||
                          curr is MovieError ||
                          curr is MovieInitial,
                      listener: (_, state) {
                        if (_pendingSearch) setState(() => _pendingSearch = false);
                      },
                      builder: (context, state) {
                        if (!_hasQuery && !_hasActiveFilter) {
                          return _buildMoviePlaceholder();
                        }
                        if (state is MovieLoading && _pendingSearch) {
                          return _buildShimmerList();
                        }
                        if (state is MovieSearchLoaded) {
                          final filteredTitle = _applyClientMovieGenreFilter(state.titleMovies);
                          final filteredActor = _applyClientMovieGenreFilter(state.actorMovies);
                          if (filteredTitle.isEmpty && filteredActor.isEmpty) return _buildEmptyResult();
                          return _buildMovieSearchResults(
                            titleMovies: filteredTitle,
                            actorMovies: filteredActor,
                            actorName: state.actorName,
                          );
                        }
                        if (state is MovieDiscoverLoaded) {
                          final filtered = _movieFilter.sortBy == MovieSortOption.trending
                              ? _applyClientMovieGenreFilter(state.movies)
                              : state.movies;
                          if (filtered.isEmpty) return _buildEmptyResult();
                          return _buildMovieResultsList(filtered);
                        }
                        if (state is MovieError) {
                          return Center(
                            child: Text(state.message,
                                style: AppTypography.body1
                                    .copyWith(color: AppColors.error)),
                          );
                        }
                        if (_pendingSearch) return _buildShimmerList();
                        return _buildMoviePlaceholder();
                      },
                    )
                  : BlocConsumer<TvBloc, TvState>(
                      key: const ValueKey('tv-search'),
                      buildWhen: (_, curr) =>
                          curr is TvInitial ||
                          curr is TvLoading ||
                          curr is TvSearchLoaded ||
                          curr is TvDiscoverLoaded ||
                          curr is TvError,
                      listenWhen: (_, curr) =>
                          curr is TvSearchLoaded ||
                          curr is TvDiscoverLoaded ||
                          curr is TvError ||
                          curr is TvInitial,
                      listener: (_, state) {
                        if (_pendingSearch) setState(() => _pendingSearch = false);
                      },
                      builder: (context, state) {
                        if (!_hasQuery && !_hasActiveFilter) {
                          return _buildTvPlaceholder();
                        }
                        if (state is TvLoading && _pendingSearch) {
                          return _buildShimmerList();
                        }
                        if (state is TvSearchLoaded) {
                          final filteredTitle = _applyClientTvGenreFilter(state.titleShows);
                          final filteredActor = _applyClientTvGenreFilter(state.actorShows);
                          if (filteredTitle.isEmpty && filteredActor.isEmpty) return _buildEmptyResult();
                          return _buildTvSearchResults(
                            titleShows: filteredTitle,
                            actorShows: filteredActor,
                            actorName: state.actorName,
                          );
                        }
                        if (state is TvDiscoverLoaded) {
                          final filtered = _tvFilter.sortBy == MovieSortOption.trending
                              ? _applyClientTvGenreFilter(state.shows)
                              : state.shows;
                          if (filtered.isEmpty) return _buildEmptyResult();
                          return _buildTvResultsList(filtered);
                        }
                        if (state is TvError) {
                          return Center(
                            child: Text(state.message,
                                style: AppTypography.body1
                                    .copyWith(color: AppColors.error)),
                          );
                        }
                        if (_pendingSearch) return _buildShimmerList();
                        return _buildTvPlaceholder();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE TOGGLE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildModeToggle() => Padding(
        padding: AppSpacing.hPad,
        child: Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _toggleSegment(
                label:    'Movies',
                icon:     Icons.movie_rounded,
                isActive: _isMovieMode,
                onTap:    () => _onModeSwitch(true),
              ),
              _toggleSegment(
                label:    'TV Shows',
                icon:     Icons.tv_rounded,
                isActive: !_isMovieMode,
                onTap:    () => _onModeSwitch(false),
              ),
            ],
          ),
        ),
      );

  Widget _toggleSegment({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryMuted
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd - 3),
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs4),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // PLACEHOLDER (no query + no filter)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMoviePlaceholder() {
    // Hardcoded common movie genre IDs — avoids a network request on the
    // placeholder screen. TV uses the dynamically loaded _tvGenres list.
    const genres = [
      {'label': 'Action',    'id': 28},
      {'label': 'Drama',     'id': 18},
      {'label': 'Comedy',    'id': 35},
      {'label': 'Horror',    'id': 27},
      {'label': 'Sci-Fi',    'id': 878},
      {'label': 'Romance',   'id': 10749},
    ];
    return SingleChildScrollView(
      padding: AppSpacing.hPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Browse Genres',
            style: AppTypography.subtitle2
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: genres.map((genre) {
              return GestureDetector(
                onTap: () => context.push(
                  AppRouter.movieList,
                  extra: 'genre_${genre['id']}',
                ),
                child: _genreChip(genre['label'] as String),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Icon(
              Icons.movie_filter_rounded,
              size: AppSpacing.iconXxl,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Find your favorite films',
              style: AppTypography.body1
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Center(
            child: Text(
              'Type a title or use filters',
              style: AppTypography.body2
                  .copyWith(color: AppColors.textDisabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvPlaceholder() {
    return SingleChildScrollView(
      padding: AppSpacing.hPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          if (_tvGenres.isNotEmpty) ...[
            Text(
              'Browse Genres',
              style: AppTypography.subtitle2
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _tvGenres.map((g) {
                return GestureDetector(
                  onTap: () => context.push(
                    AppRouter.tvList,
                    extra: 'genre_${g.id}',
                  ),
                  child: _genreChip(g.name),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          Center(
            child: Icon(
              Icons.live_tv_rounded,
              size: AppSpacing.iconXxl,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Find your favorite shows',
              style: AppTypography.body1
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Center(
            child: Text(
              'Type a title or use filters',
              style: AppTypography.body2
                  .copyWith(color: AppColors.textDisabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreChip(String label) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SHIMMER (loading state)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.searchPosterW,
                height: AppSpacing.searchPosterH,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerLine(double.infinity, 14),
                    const SizedBox(height: AppSpacing.xs),
                    _shimmerLine(120, 12),
                    const SizedBox(height: AppSpacing.xs),
                    _shimmerLine(double.infinity, 12),
                    const SizedBox(height: AppSpacing.xs4),
                    _shimmerLine(160, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerLine(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY RESULT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyResult() {
    final noun = _isMovieMode ? 'movies' : 'TV shows';

    if (!_hasActiveFilter) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: AppSpacing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No $noun found',
              style: AppTypography.body1
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Try a different keyword',
              style: AppTypography.body2
                  .copyWith(color: AppColors.textDisabled),
            ),
          ],
        ),
      );
    }

    final desc = _activeFilterDesc();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: AppSpacing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No $noun found',
              style: AppTypography.body1
                  .copyWith(color: AppColors.textTertiary),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs4),
              Text(
                'for $desc',
                textAlign: TextAlign.center,
                style: AppTypography.body2
                    .copyWith(color: AppColors.textDisabled),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showFilterSheet,
                    child: Text(
                      'Edit Filter',
                      style: AppTypography.button
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onFilterChanged(const MovieFilter()),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _activeFilterDesc() {
    final filter = _activeFilter;
    final parts = <String>[];
    if (filter.sortBy != MovieSortOption.popular) parts.add(filter.sortBy.label);
    if (filter.genreNames.isNotEmpty) parts.add(filter.genreNames.join(' & '));
    return parts.join(', ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESULTS LIST — MOVIES  (discover only — search uses _buildMovieSearchResults)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMovieResultsList(List<MovieModel> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
          ),
          child: Text(
            _buildResultsLabel(movies.length),
            style: AppTypography.caption
                .copyWith(color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
            ),
            itemCount: movies.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final movie = movies[i];
              return _SearchResultItem(
                movie: movie,
                onTap: () => context.push(
                  AppRouter.movieDetail,
                  extra: {
                    'id':          movie.id,
                    'title':       movie.title,
                    'overview':    movie.overview,
                    'posterUrl':   movie.fullPosterUrl,
                    'backdropUrl': movie.fullBackdropUrl,
                    'rating':      movie.voteAverage,
                    'releaseDate': movie.releaseDate,
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESULTS LIST — TV SHOWS  (discover only)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTvResultsList(List<TvModel> shows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
          ),
          child: Text(
            _buildResultsLabel(shows.length),
            style: AppTypography.caption
                .copyWith(color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
            ),
            itemCount: shows.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final show = shows[i];
              return _TvSearchResultItem(
                show: show,
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH RESULTS — TWO-SECTION (MOVIES)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMovieSearchResults({
    required List<MovieModel> titleMovies,
    required List<MovieModel> actorMovies,
    String? actorName,
  }) {
    final hasBoth      = titleMovies.isNotEmpty && actorMovies.isNotEmpty && actorName != null;
    final hasOnlyTitle = titleMovies.isNotEmpty && (actorMovies.isEmpty || actorName == null);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (actorName != null && actorMovies.isNotEmpty)
          _buildActorMovieSection(actorMovies, actorName),

        if (hasBoth)
          _buildSectionDivider('By Title · ${titleMovies.length} results'),

        if (hasOnlyTitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Text(
              _buildResultsLabel(titleMovies.length),
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),

        ...titleMovies.map((movie) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
          ),
          child: _SearchResultItem(
            movie: movie,
            onTap: () => context.push(
              AppRouter.movieDetail,
              extra: {
                'id':          movie.id,
                'title':       movie.title,
                'overview':    movie.overview,
                'posterUrl':   movie.fullPosterUrl,
                'backdropUrl': movie.fullBackdropUrl,
                'rating':      movie.voteAverage,
                'releaseDate': movie.releaseDate,
              },
            ),
          ),
        )),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH RESULTS — TWO-SECTION (TV SHOWS)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTvSearchResults({
    required List<TvModel> titleShows,
    required List<TvModel> actorShows,
    String? actorName,
  }) {
    final hasBoth      = titleShows.isNotEmpty && actorShows.isNotEmpty && actorName != null;
    final hasOnlyTitle = titleShows.isNotEmpty && (actorShows.isEmpty || actorName == null);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (actorName != null && actorShows.isNotEmpty)
          _buildActorTvSection(actorShows, actorName),

        if (hasBoth)
          _buildSectionDivider('By Title · ${titleShows.length} results'),

        if (hasOnlyTitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Text(
              _buildResultsLabel(titleShows.length),
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),

        ...titleShows.map((show) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
          ),
          child: _TvSearchResultItem(
            show: show,
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
          ),
        )),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTOR SECTION — shared layout (banner + horizontal poster scroll)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActorSection({
    required String actorName,
    required int itemCount,
    required String mediaLabel,
    required Widget Function(int index) posterBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor identity card
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(actorName, style: AppTypography.subtitle2),
                        Text(
                          'Actor · $itemCount $mediaLabel',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Horizontal poster scroll
          SizedBox(
            height: AppSpacing.similarPosterH + 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: itemCount,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs + 1),
              itemBuilder: (_, i) => posterBuilder(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorMovieSection(List<MovieModel> movies, String actorName) =>
      _buildActorSection(
        actorName:  actorName,
        itemCount:  movies.length,
        mediaLabel: 'films',
        posterBuilder: (i) {
          final m = movies[i];
          return _ActorPosterCard(
            posterUrl: m.fullPosterUrl,
            title:     m.title,
            rating:    m.voteAverage,
            onTap: () => context.push(AppRouter.movieDetail, extra: {
              'id':          m.id,
              'title':       m.title,
              'overview':    m.overview,
              'posterUrl':   m.fullPosterUrl,
              'backdropUrl': m.fullBackdropUrl,
              'rating':      m.voteAverage,
              'releaseDate': m.releaseDate,
            }),
          );
        },
      );

  Widget _buildActorTvSection(List<TvModel> shows, String actorName) =>
      _buildActorSection(
        actorName:  actorName,
        itemCount:  shows.length,
        mediaLabel: 'shows',
        posterBuilder: (i) {
          final s = shows[i];
          return _ActorPosterCard(
            posterUrl: s.fullPosterUrl,
            title:     s.displayTitle,
            rating:    s.voteAverage,
            onTap: () => context.push(AppRouter.tvDetail, extra: {
              'id':           s.id,
              'name':         s.name,
              'overview':     s.overview,
              'posterUrl':    s.fullPosterUrl,
              'backdropUrl':  s.fullBackdropUrl,
              'rating':       s.voteAverage,
              'firstAirDate': s.firstAirDate,
            }),
          );
        },
      );
}

// ── ACTIVE FILTER CHIP ────────────────────────────────────────────────────────
class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm, 0, AppSpacing.xs4, 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FILTER BOTTOM SHEET ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final MovieFilter initialFilter;
  final List<GenreModel> genres;
  final bool hasKeyword;
  /// When true, the "Longest" sort option is hidden — TV has no runtime sort.
  final bool isTV;

  const _FilterSheet({
    required this.initialFilter,
    required this.genres,
    this.hasKeyword = false,
    this.isTV = false,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet>
    with SingleTickerProviderStateMixin {
  late MovieFilter _draft;
  late AnimationController _animCtrl;
  late List<MovieSortOption> _sortOptions;
  late List<Animation<double>> _sortFades;
  late List<Animation<Offset>> _sortSlides;
  late Animation<double> _genreFade;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;

    // TV excludes "Longest" — no episode_run_time sort on TMDB.
    _sortOptions = widget.isTV
        ? MovieSortOption.values
            .where((o) => o != MovieSortOption.longest)
            .toList()
        : MovieSortOption.values.toList();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    final sortCount = _sortOptions.length;
    _sortFades = List.generate(sortCount, (i) {
      final start = i * 0.08;
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );
    });
    _sortSlides = List.generate(sortCount, (i) {
      final start = i * 0.08;
      return Tween<Offset>(
        begin: const Offset(-0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ));
    });
    _genreFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.40, 0.90, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleGenre(int id, String name) {
    final ids   = List<int>.from(_draft.genreIds);
    final names = List<String>.from(_draft.genreNames);
    if (ids.contains(id)) {
      final idx = ids.indexOf(id);
      ids.removeAt(idx);
      names.removeAt(idx);
    } else {
      ids.add(id);
      names.add(name);
    }
    setState(() => _draft = _draft.copyWith(genreIds: ids, genreNames: names));
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── DRAG HANDLE ──────────────────────────────────────
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

            // ── SHEET HEADER ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.xs, 0,
              ),
              child: Row(
                children: [
                  Text('Filter & Sort', style: AppTypography.subtitle1),
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

            // ── SCROLLABLE CONTENT ────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort section
                    Row(
                      children: [
                        Text(
                          'SORT BY',
                          style: AppTypography.overline.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (widget.hasKeyword) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.block_rounded,
                            size: 13,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ],
                    ),
                    if (widget.hasKeyword) ...[
                      const SizedBox(height: AppSpacing.xs4),
                      Text(
                        'Clear keyword to apply sort',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    ..._sortOptions.asMap().entries.map((e) {
                      final i   = e.key;
                      final opt = e.value;
                      return FadeTransition(
                        opacity: _sortFades[i],
                        child: SlideTransition(
                          position: _sortSlides[i],
                          child: _RadioOption(
                            label: opt.label,
                            selected: _draft.sortBy == opt,
                            disabled: widget.hasKeyword,
                            onTap: widget.hasKeyword
                                ? null
                                : () => setState(
                                    () => _draft =
                                        _draft.copyWith(sortBy: opt),
                                  ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),

                    // Genre section
                    FadeTransition(
                      opacity: _genreFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'GENRE',
                                style: AppTypography.overline.copyWith(
                                  color: AppColors.textTertiary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (_draft.genreIds.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '${_draft.genreIds.length}',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _CheckboxOption(
                            label: 'All Genres',
                            selected: _draft.genreIds.isEmpty,
                            onTap: () => setState(
                              () => _draft = _draft.copyWith(
                                genreIds: [], genreNames: [],
                              ),
                            ),
                          ),
                          if (widget.genres.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Center(
                                child: Text(
                                  'Loading genres...',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...widget.genres.map((g) => _CheckboxOption(
                              label: g.name,
                              selected: _draft.genreIds.contains(g.id),
                              onTap: () => _toggleGenre(g.id, g.name),
                            )),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ACTION BUTTONS ────────────────────────────────────
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm,
                AppSpacing.lg, AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, const MovieFilter()),
                      child: Text(
                        'Reset',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _draft),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ── RADIO OPTION (sort — single-select) ──────────────────────────────────────
class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  const _RadioOption({
    required this.label,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              (!disabled && selected)
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: disabled
                  ? AppColors.textDisabled
                  : selected
                      ? AppColors.primary
                      : AppColors.textDisabled,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.body1.copyWith(
                color: disabled
                    ? AppColors.textDisabled
                    : selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                fontWeight: (!disabled && selected)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CHECKBOX OPTION (genre — multi-select) ────────────────────────────────────
class _CheckboxOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckboxOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textDisabled,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.textPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.body1.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SEARCH RESULT ITEM — MOVIE ────────────────────────────────────────────────
class _SearchResultItem extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;
  const _SearchResultItem({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterUrl,
                width: AppSpacing.searchPosterW,
                height: AppSpacing.searchPosterH,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: AppSpacing.searchPosterW,
                  height: AppSpacing.searchPosterH,
                  color: AppColors.surfaceElevated,
                ),
                errorWidget: (_, _, _) => Container(
                  width: AppSpacing.searchPosterW,
                  height: AppSpacing.searchPosterH,
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textDisabled,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle2,
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accent1, size: 14),
                      const SizedBox(width: AppSpacing.xs4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (movie.releaseDate.length >= 4) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          movie.releaseDate.substring(0, 4),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (movie.overview.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: AppSpacing.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

// ── ACTOR POSTER CARD (horizontal scroll in actor section) ───────────────────
class _ActorPosterCard extends StatelessWidget {
  final String posterUrl;
  final String title;
  final double rating;
  final VoidCallback onTap;

  const _ActorPosterCard({
    required this.posterUrl,
    required this.title,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppSpacing.similarPosterW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                width: AppSpacing.similarPosterW,
                height: AppSpacing.similarPosterH,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppColors.surface,
                  width: AppSpacing.similarPosterW,
                  height: AppSpacing.similarPosterH,
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surface,
                  width: AppSpacing.similarPosterW,
                  height: AppSpacing.similarPosterH,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.accent1, size: 9),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent1,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── SEARCH RESULT ITEM — TV SHOW ──────────────────────────────────────────────
class _TvSearchResultItem extends StatelessWidget {
  final TvModel show;
  final VoidCallback onTap;
  const _TvSearchResultItem({required this.show, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Poster + "TV" badge overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: show.fullPosterUrl,
                    width: AppSpacing.searchPosterW,
                    height: AppSpacing.searchPosterH,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: AppSpacing.searchPosterW,
                      height: AppSpacing.searchPosterH,
                      color: AppColors.surfaceElevated,
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: AppSpacing.searchPosterW,
                      height: AppSpacing.searchPosterH,
                      color: AppColors.surfaceElevated,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textDisabled,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent2.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusXs - 2,
                      ),
                    ),
                    child: const Text(
                      'TV',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle2,
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accent1, size: 14),
                      const SizedBox(width: AppSpacing.xs4),
                      Text(
                        show.voteAverage.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (show.firstAirDate.length >= 4) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          show.firstAirDate.substring(0, 4),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (show.overview.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      show.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: AppSpacing.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}
