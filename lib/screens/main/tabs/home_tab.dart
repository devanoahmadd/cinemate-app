import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../bloc/auth_bloc/auth_bloc.dart';
import '../../../bloc/auth_bloc/auth_state.dart';
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

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // ── Hero carousel ────────────────────────────────────────────────
  late PageController _heroController;
  List<MovieModel> _heroMovies    = [];
  bool _heroMoviesSet             = false;
  int  _currentHeroPage           = 0;
  Timer? _autoSlideTimer;

  int _activeTab = 0; // 0 = Movies, 1 = TV Shows

  // ── Movie cache ──────────────────────────────────────────────────
  List<MovieModel> _cachedNowPlaying = [];
  List<MovieModel> _cachedPopular    = [];
  bool _hasMovieCache = false;

  // ── TV cache ─────────────────────────────────────────────────────
  List<TvModel> _cachedTvAiringToday = [];
  bool _hasTvCache = false;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();

    final movieState = context.read<MovieBloc>().state;
    if (movieState is MovieHomeLoaded) {
      _cachedNowPlaying = movieState.nowPlaying;
      _cachedPopular    = movieState.popular;
      _hasMovieCache    = true;
      _pickHeroMovies();
    } else {
      context.read<MovieBloc>().add(MovieFetchHome());
    }

    final tvState = context.read<TvBloc>().state;
    if (tvState is TvHomeLoaded) {
      _cachedTvAiringToday = tvState.airingToday;
      _hasTvCache          = true;
    } else {
      context.read<TvBloc>().add(TvFetchHome());
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  // ── Hero carousel logic ──────────────────────────────────────────

  /// Pick 4 random films from nowPlaying, then start auto-slide.
  void _pickHeroMovies() {
    if (_heroMoviesSet || _cachedNowPlaying.isEmpty) return;
    final pool = List<MovieModel>.from(_cachedNowPlaying);
    pool.shuffle(Random());
    setState(() {
      _heroMovies      = pool.take(4).toList();
      _heroMoviesSet   = true;
      _currentHeroPage = 0;
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _heroMovies.isEmpty) return;
      final next = (_currentHeroPage + 1) % _heroMovies.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlide() => _autoSlideTimer?.cancel();

  void _fetchHome() {
    _heroMoviesSet   = false;
    _heroMovies      = [];
    _currentHeroPage = 0;
    if (_heroController.hasClients) _heroController.jumpToPage(0);
    _stopAutoSlide();
    context.read<MovieBloc>().add(MovieFetchHome());
    context.read<TvBloc>().add(TvFetchHome());
  }

  // ── Movie category definitions ───────────────────────────────────
  final List<Map<String, dynamic>> _movieCategories = [
    {'label': 'Popular',     'icon': Icons.local_fire_department_rounded, 'value': 'popular',     'color': AppColors.primary},
    {'label': 'Now Playing', 'icon': Icons.play_circle_rounded,           'value': 'now_playing', 'color': AppColors.accent2},
    {'label': 'Top Rated',   'icon': Icons.star_rounded,                  'value': 'top_rated',   'color': AppColors.accent1},
    {'label': 'Upcoming',    'icon': Icons.calendar_month_rounded,        'value': 'upcoming',    'color': const Color(0xFF9B8FFF)},
  ];

  // ── TV category definitions ──────────────────────────────────────
  final List<Map<String, dynamic>> _tvCategories = [
    {'label': 'Popular',      'icon': Icons.local_fire_department_rounded, 'value': 'popular',      'color': AppColors.primary},
    {'label': 'Airing Today', 'icon': Icons.live_tv_rounded,               'value': 'airing_today', 'color': AppColors.accent2},
    {'label': 'On The Air',   'icon': Icons.wifi_rounded,                  'value': 'on_the_air',   'color': const Color(0xFF7986CB)},
    {'label': 'Top Rated',    'icon': Icons.star_rounded,                  'value': 'top_rated',    'color': AppColors.accent1},
  ];

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final String username = authState is AuthAuthenticated
        ? (authState.user.email?.split('@').first ?? 'User')
        : 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, movieState) {
          if (movieState is MovieHomeLoaded) {
            _cachedNowPlaying = movieState.nowPlaying;
            _cachedPopular    = movieState.popular;
            _hasMovieCache    = true;
            if (!_heroMoviesSet && _cachedNowPlaying.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pickHeroMovies();
              });
            }
          }
          final movieLoading =
              !_hasMovieCache && (movieState is MovieLoading || movieState is MovieInitial);

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.background,
            onRefresh: () async {
              _fetchHome();
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader(username)),

                // ── Hero carousel ────────────────────────────────────
                SliverToBoxAdapter(
                  child: movieLoading ? _heroBannerSkeleton() : _buildHeroBanner(),
                ),

                // ── Sticky tab row ───────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabDelegate(
                    height: 60,
                    child: _buildTabRow(),
                  ),
                ),

                // ── Tab content ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: BlocBuilder<TvBloc, TvState>(
                    builder: (context, tvState) {
                      if (tvState is TvHomeLoaded) {
                        _cachedTvAiringToday = tvState.airingToday;
                        _hasTvCache          = true;
                      }
                      final tvLoading = !_hasTvCache &&
                          (tvState is TvLoading || tvState is TvInitial);

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Column(
                          key: ValueKey(_activeTab),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _activeTab == 0
                              ? [
                                  _buildSectionTitle('Categories'),
                                  _buildMovieCategoryGrid(),
                                  _buildSectionTitle('Trending Today', badge: 'HOT'),
                                  movieLoading ? _trendingSkeleton() : _buildTrendingList(),
                                  const SizedBox(height: AppSpacing.xxl),
                                ]
                              : [
                                  _buildSectionTitle('Categories'),
                                  _buildTvCategoryGrid(),
                                  _buildSectionTitle('Airing Today'),
                                  tvLoading ? _tvAiringSkeleton() : _buildTvAiringRow(),
                                  const SizedBox(height: AppSpacing.xxl),
                                ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB ROW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTabRow() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          children: [
            _tabSegment('Movies',   Icons.movie_rounded, 0),
            _tabSegment('TV Shows', Icons.tv_rounded,    1),
          ],
        ),
      ),
    );
  }

  Widget _tabSegment(String label, IconData icon, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body2.copyWith(
                  color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(String username) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.md,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hey, $username!', style: AppTypography.greeting),
              const SizedBox(height: 2),
              Text("What's on your watchlist today?",
                  style: AppTypography.greetingSub),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(color: AppColors.primaryGlow),
            ),
            child: Image.asset(
              'assets/icon/cinemate_icon.png',
              width: AppSpacing.headerLogoSize,
              height: AppSpacing.headerLogoSize,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HERO BANNER — carousel
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    if (_heroMovies.isEmpty) return _heroBannerSkeleton();

    return SizedBox(
      // extra 20px below the banner for dot indicators
      height: AppSpacing.heroBannerHeight + 20,
      child: Column(
        children: [
          // ── PageView ────────────────────────────────────────────
          SizedBox(
            height: AppSpacing.heroBannerHeight,
            child: PageView.builder(
              controller: _heroController,
              itemCount: _heroMovies.length,
              onPageChanged: (i) {
                // Restart timer on manual swipe so user gets a full 4s before
                // next auto-advance.
                _stopAutoSlide();
                setState(() => _currentHeroPage = i);
                _startAutoSlide();
              },
              itemBuilder: (context, i) {
                final featured = _heroMovies[i];
                return GestureDetector(
                  onTap: () => _pushMovieDetail(featured),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: AppShadows.heroBanner,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Backdrop image
                          CachedNetworkImage(
                            imageUrl: featured.fullBackdropUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: AppColors.surface),
                            errorWidget: (_, _, _) => CachedNetworkImage(
                              imageUrl: featured.fullPosterUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Gradient
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppShadows.heroBannerGradient,
                            ),
                          ),
                          // "NOW PLAYING" badge
                          Positioned(
                            top: AppSpacing.sm,
                            left: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      size: 6,
                                      color: AppColors.textPrimary),
                                  const SizedBox(width: 5),
                                  Text('NOW PLAYING',
                                      style: AppTypography.overline),
                                ],
                              ),
                            ),
                          ),
                          // Bottom info row
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          featured.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.subtitle1
                                              .copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: AppColors.accent1,
                                                size: 15),
                                            const SizedBox(
                                                width: AppSpacing.xs4),
                                            Text(
                                              featured.voteAverage
                                                  .toStringAsFixed(1),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color:
                                                    AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (featured.releaseDate
                                                    .length >=
                                                4) ...[
                                              const SizedBox(
                                                  width: AppSpacing.xs),
                                              Container(
                                                width: 4,
                                                height: 4,
                                                decoration:
                                                    const BoxDecoration(
                                                  color:
                                                      AppColors.textTertiary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.xs),
                                              Text(
                                                featured.releaseDate
                                                    .substring(0, 4),
                                                style:
                                                    AppTypography.caption,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Details pill button — frosted glass so it
                                  // looks clean on any backdrop color.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusFull),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.40),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.textPrimary,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Details',
                                          style: AppTypography.overline
                                              .copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Dot indicators ──────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _heroMovies.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  _currentHeroPage == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentHeroPage == i
                      ? AppColors.primary
                      : AppColors.textDisabled.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBannerSkeleton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          height: AppSpacing.heroBannerHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(title, style: AppTypography.subtitle1),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(badge, style: AppTypography.overline),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // MOVIE CATEGORY GRID
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMovieCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _movieCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, i) {
          final cat   = _movieCategories[i];
          final color = cat['color'] as Color;
          return GestureDetector(
            onTap: () =>
                context.push(AppRouter.movieList, extra: cat['value']),
            child: _categoryCell(
              icon:  cat['icon']  as IconData,
              label: cat['label'] as String,
              color: color,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TV CATEGORY GRID
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTvCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _tvCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, i) {
          final cat   = _tvCategories[i];
          final color = cat['color'] as Color;
          return GestureDetector(
            onTap: () =>
                context.push(AppRouter.tvList, extra: cat['value']),
            child: _categoryCell(
              icon:  cat['icon']  as IconData,
              label: cat['label'] as String,
              color: color,
            ),
          );
        },
      ),
    );
  }

  Widget _categoryCell({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────
  // TRENDING LIST (movies)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTrendingList() {
    if (_cachedPopular.isEmpty) return _trendingSkeleton();

    final trending = _cachedPopular.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: List.generate(
          trending.length,
          (i) => _TrendingItem(
            rank:  i + 1,
            movie: trending[i],
            onTap: () => _pushMovieDetail(trending[i]),
          ),
        ),
      ),
    );
  }

  Widget _trendingSkeleton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────
  // AIRING TODAY TV ROW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTvAiringRow() {
    if (_cachedTvAiringToday.isEmpty) return _tvAiringSkeleton();

    return SizedBox(
      height: AppSpacing.similarPosterH + 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _cachedTvAiringToday.length.clamp(0, 10),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final show = _cachedTvAiringToday[i];
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
            child: SizedBox(
              width: AppSpacing.similarPosterW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd - 2),
                        child: CachedNetworkImage(
                          imageUrl: show.fullPosterUrl,
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
                            child: const Icon(Icons.broken_image_rounded,
                                color: AppColors.textDisabled),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent2.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXs - 2),
                          ),
                          child: Text(
                            'TV',
                            style: AppTypography.overline.copyWith(
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
                  const SizedBox(height: 5),
                  Text(
                    show.displayTitle,
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
                        show.voteAverage.toStringAsFixed(1),
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
        },
      ),
    );
  }

  Widget _tvAiringSkeleton() => SizedBox(
        height: AppSpacing.similarPosterH + 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (_, _) => Container(
            width: AppSpacing.similarPosterW,
            height: AppSpacing.similarPosterH,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd - 2),
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────
  void _pushMovieDetail(MovieModel movie) {
    context.push(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY TAB DELEGATE
// ─────────────────────────────────────────────────────────────────────────────
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _StickyTabDelegate({required this.child, required this.height});

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyTabDelegate old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// TRENDING ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _TrendingItem extends StatelessWidget {
  final int rank;
  final MovieModel movie;
  final VoidCallback onTap;

  const _TrendingItem({
    required this.rank,
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const rankColors = [
      Color(0xFFFFD700), // Gold   — #1
      Color(0xFFB8C4CC), // Silver — #2
      Color(0xFFCD7F32), // Bronze — #3
    ];
    final rankColor =
        rank <= 3 ? rankColors[rank - 1] : AppColors.textDisabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMdPlus),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                textAlign: TextAlign.center,
                style: AppTypography.subtitle1.copyWith(
                  color: rankColor,
                  fontSize: 15,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterUrl,
                width: AppSpacing.trendingPosterW,
                height: AppSpacing.trendingPosterH,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: AppSpacing.trendingPosterW,
                  height: AppSpacing.trendingPosterH,
                  color: AppColors.surfaceElevated,
                ),
                errorWidget: (_, _, _) => Container(
                  width: AppSpacing.trendingPosterW,
                  height: AppSpacing.trendingPosterH,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textDisabled, size: 16),
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accent1, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (movie.releaseDate.length >= 4) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          movie.releaseDate.substring(0, 4),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textDisabled, size: AppSpacing.iconMd),
          ],
        ),
      ),
    );
  }
}
