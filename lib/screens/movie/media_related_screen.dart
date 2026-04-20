import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/movie_service.dart';

enum MediaRelatedType { similar, recommendations }

class MediaRelatedScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final MediaRelatedType type;
  final List<MovieModel> initialMovies;

  const MediaRelatedScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.type,
    required this.initialMovies,
  });

  @override
  State<MediaRelatedScreen> createState() => _MediaRelatedScreenState();
}

class _MediaRelatedScreenState extends State<MediaRelatedScreen> {
  final _service = MovieService();

  late List<MovieModel> _movies;
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _movies = List.of(widget.initialMovies);
    _hasMore = widget.initialMovies.length >= 20;
  }

  String get _screenTitle => switch (widget.type) {
        MediaRelatedType.similar         => 'Similar Movies',
        MediaRelatedType.recommendations => 'Recommendations',
      };

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final List<MovieModel> next;
      if (widget.type == MediaRelatedType.similar) {
        next = await _service.getMovieSimilar(widget.movieId, page: _page + 1);
      } else {
        next = await _service.getMovieRecommendations(
            widget.movieId, page: _page + 1);
      }
      if (!mounted) return;
      setState(() {
        _page++;
        _movies.addAll(next);
        _hasMore = next.length >= 20;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load more movies')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.xs4,
              bottom: AppSpacing.xs4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_screenTitle, style: AppTypography.subtitle1),
            Text(
              widget.movieTitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _movies.isEmpty
          ? Center(
              child: Text(
                'No movies found.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _MovieCard(
                        movie: _movies[i],
                        onTap: () => context.push(
                          AppRouter.movieDetail,
                          extra: {
                            'id': _movies[i].id,
                            'title': _movies[i].title,
                            'overview': _movies[i].overview,
                            'posterUrl': _movies[i].fullPosterUrl,
                            'backdropUrl': _movies[i].fullBackdropUrl,
                            'rating': _movies[i].voteAverage,
                            'releaseDate': _movies[i].releaseDate,
                          },
                        ),
                      ),
                      childCount: _movies.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.62,
                    ),
                  ),
                ),
                if (_hasMore)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ElevatedButton(
                        onPressed: _isLoadingMore ? null : _loadMore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textSecondary,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.buttonRadius,
                            side: const BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: _isLoadingMore
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Load More',
                                    style: AppTypography.button.copyWith(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
              ],
            ),
    );
  }
}

// ── Movie Card ───────────────────────────────────────────────────────────────

class _MovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterUrl,
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
          ),
          const SizedBox(height: 5),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.accent1, size: 10),
              const SizedBox(width: 2),
              Text(
                movie.voteAverage.toStringAsFixed(1),
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
    );
  }
}
