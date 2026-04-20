import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/review_model.dart';
import '../../data/services/movie_service.dart';
import '../../widgets/review_card.dart';

class ReviewsScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final double voteAverage;
  final int voteCount;
  final List<ReviewModel> initialReviews;

  const ReviewsScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.voteAverage,
    required this.voteCount,
    required this.initialReviews,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _service = MovieService();

  late List<ReviewModel> _reviews;
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _reviews = List.of(widget.initialReviews);
    _hasMore = widget.initialReviews.length >= 20;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = await _service.getMovieReviews(widget.movieId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _reviews.addAll(next);
        _hasMore = next.length >= 20;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load more reviews')),
      );
    }
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildStarRow(double avg) {
    final filled = (avg / 2).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star_rounded,
          size: 12,
          color: i < filled
              ? AppColors.accent1
              : AppColors.accent1.withValues(alpha: 0.15),
        ),
      ),
    );
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
            Text('User Reviews', style: AppTypography.subtitle1),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          // Score summary bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      widget.voteAverage.toStringAsFixed(1),
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.accent1,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'TMDB SCORE',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(width: 1, height: 36, color: AppColors.divider),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRow(widget.voteAverage),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      '${_formatCount(widget.voteCount)} votes',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                    Text(
                      'vote_average · vote_count · TMDB',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Review count label
          Row(
            children: [
              Text(
                '${_reviews.length} Review${_reviews.length == 1 ? '' : 's'}',
                style: AppTypography.subtitle1,
              ),
              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs4),
                  child: Text(
                    '+',
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Reviews or empty state
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'No user reviews yet.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            )
          else
            ..._reviews.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ReviewCard(review: r),
              ),
            ),
          // Load More
          if (_hasMore) ...[
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: _isLoadingMore ? null : _loadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textSecondary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
          ],
        ],
      ),
    );
  }
}
