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
import '../../../core/routes/app_router.dart';
import '../../../data/models/movie_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Index hero banner
  int _heroIndex = 0;
  bool _heroIndexSet = false;

  // Cache lokal — tetap ada selama widget hidup di IndexedStack
  List<MovieModel> _cachedNowPlaying = [];
  List<MovieModel> _cachedPopular = [];
  bool _hasCache = false;

  @override
  void initState() {
    super.initState();
    // Cek state Bloc
    final currentState = context.read<MovieBloc>().state;
    if (currentState is MovieHomeLoaded) {
      _cachedNowPlaying = currentState.nowPlaying;
      _cachedPopular = currentState.popular;
      _hasCache = true;
      if (currentState.nowPlaying.isNotEmpty) {
        _heroIndex = Random().nextInt(currentState.nowPlaying.length.clamp(1, 8));
        _heroIndexSet = true;
      }
    } else {
      _fetchHome();
    }
  }

  void _fetchHome() {
    _heroIndexSet = false;
    context.read<MovieBloc>().add(MovieFetchHome());
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Popular',
      'icon': Icons.local_fire_department_rounded,
      'value': 'popular',
      'color': const Color(0xFFFF6B6B),
    },
    {
      'label': 'Now Playing',
      'icon': Icons.play_circle_rounded,
      'value': 'now_playing',
      'color': const Color(0xFF4ECDC4),
    },
    {
      'label': 'Top Rated',
      'icon': Icons.star_rounded,
      'value': 'top_rated',
      'color': const Color(0xFFFFD93D),
    },
    {
      'label': 'Upcoming',
      'icon': Icons.calendar_month_rounded,
      'value': 'upcoming',
      'color': const Color(0xFF6BCB77),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final String username = authState is AuthAuthenticated
        ? (authState.user.email?.split('@').first ?? 'Pengguna')
        : 'Pengguna';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          // Saat MovieHomeLoaded masuk, update cache lokal
          if (state is MovieHomeLoaded) {
            _cachedNowPlaying = state.nowPlaying;
            _cachedPopular = state.popular;
            _hasCache = true;
            if (!_heroIndexSet && state.nowPlaying.isNotEmpty) {
              _heroIndex = Random().nextInt(state.nowPlaying.length.clamp(1, 8));
              _heroIndexSet = true;
            }
          }

          // Hanya tampilkan loading jika belum ada cache sama sekali
          final isLoading = !_hasCache && (state is MovieLoading || state is MovieInitial);

          return RefreshIndicator(
            color: const Color(0xFFE94560),
            backgroundColor: const Color(0xFF1A1A2E),
            onRefresh: () async {
              _fetchHome();
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(username)),
                SliverToBoxAdapter(
                  child: isLoading ? _heroBannerSkeleton() : _buildHeroBanner(),
                ),
                SliverToBoxAdapter(child: _buildSectionTitle('Jelajahi')),
                SliverToBoxAdapter(child: _buildCategoryGrid()),
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Trending Hari Ini', badge: 'HOT'),
                ),
                SliverToBoxAdapter(
                  child: isLoading ? _trendingSkeleton() : _buildTrendingList(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  // HEADER
  Widget _buildHeader(String username) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $username!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mau nonton apa hari ini?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFE94560).withValues(alpha: 0.3),
              ),
            ),
            child: Image.asset(
              'assets/icon/cinemate_icon.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }

  // HERO BANNER
  Widget _buildHeroBanner() {
    if (_cachedNowPlaying.isEmpty) return _heroBannerSkeleton();

    final featured = _cachedNowPlaying[_heroIndex.clamp(0, _cachedNowPlaying.length - 1)];

    return GestureDetector(
      onTap: () => _pushDetail(featured),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 210,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94560).withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop
              CachedNetworkImage(
                imageUrl: featured.fullBackdropUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.white.withValues(alpha: 0.06)),
                errorWidget: (_, __, ___) => CachedNetworkImage(
                  imageUrl: featured.fullPosterUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info bawah
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              featured.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
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
                                    color: Color(0xFFFFD93D), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  featured.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (featured.releaseDate.length >= 4) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    featured.releaseDate.substring(0, 4),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
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
  }

  Widget _heroBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFE94560), strokeWidth: 2),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // CATEGORY GRID
  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final color = cat['color'] as Color;
          return GestureDetector(
            onTap: () =>
                context.push(AppRouter.movieList, extra: cat['value']),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    cat['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // TRENDING LIST
  Widget _buildTrendingList() {
    if (_cachedPopular.isEmpty) return _trendingSkeleton();

    final trending = _cachedPopular.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          trending.length,
          (i) => _TrendingItem(
            rank: i + 1,
            movie: trending[i],
            onTap: () => _pushDetail(trending[i]),
          ),
        ),
      ),
    );
  }

  Widget _trendingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // HELPER 
  void _pushDetail(MovieModel movie) {
    context.push(
      AppRouter.movieDetail,
      extra: {
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterUrl': movie.fullPosterUrl,
        'backdropUrl': movie.fullBackdropUrl,
        'rating': movie.voteAverage,
        'releaseDate': movie.releaseDate,
      },
    );
  }
}

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
      Color(0xFFFFD700), // Gold
      Color(0xFFB8C4CC), // Silver
      Color(0xFFCD7F32), // Bronze
    ];
    final rankColor = rank <= 3
        ? rankColors[rank - 1]
        : Colors.white.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rankColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterUrl,
                width: 46,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 46, height: 64, color: Colors.white12),
                errorWidget: (_, __, ___) => Container(
                  width: 46,
                  height: 64,
                  color: Colors.white12,
                  child: const Icon(Icons.broken_image,
                      color: Colors.white30, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD93D), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (movie.releaseDate.length >= 4) ...[
                        const SizedBox(width: 8),
                        Text(
                          movie.releaseDate.substring(0, 4),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.18), size: 20),
          ],
        ),
      ),
    );
  }
}