import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../data/models/review_model.dart';

/// Reusable review card — used in MovieDetailScreen preview and ReviewsScreen.
class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final hasRating = review.rating != null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(
              width: 3,
              color: hasRating ? AppColors.primary : AppColors.divider,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            review.initials,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs - 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.author,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                review.formattedDate,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasRating)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xs4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm - 1,
                              ),
                              border: Border.all(
                                color: AppColors.accent1.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.accent1,
                                  size: 9,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  review.rating!.toStringAsFixed(0),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accent1,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xs4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm - 1,
                              ),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              'No rating',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs - 1),
                    Padding(
                      padding: const EdgeInsets.only(left: 35),
                      child: Text(
                        review.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
