import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/collection_detail_model.dart';
import '../../data/services/movie_service.dart';

class CollectionScreen extends StatefulWidget {
  final int collectionId;
  final String collectionName;

  const CollectionScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _service = MovieService();

  bool _isLoading = true;
  bool _hasError = false;
  CollectionDetailModel? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getCollectionDetails(widget.collectionId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            sliver: _isLoading
                ? _buildSkeletonSliver()
                : _hasError
                    ? _buildErrorSliver()
                    : _buildContentSliver(_data!),
          ),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final backdrop = _data?.fullBackdropUrl ?? '';
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 200,
      pinned: true,
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
            color: AppColors.overlay.withValues(alpha: 0.55),
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
      title: Text(
        _data?.name ?? widget.collectionName,
        style: AppTypography.subtitle1,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdrop.isNotEmpty)
              CachedNetworkImage(
                imageUrl: backdrop,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.surface),
                errorWidget: (_, _, _) =>
                    Container(color: AppColors.surface),
              )
            else
              Container(color: AppColors.surface),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────
  Widget _buildSkeletonSliver() => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceElevated,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 115,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 14,
                            color: AppColors.surface),
                        const SizedBox(height: 6),
                        Container(
                            width: 60,
                            height: 11,
                            color: AppColors.surface),
                        const SizedBox(height: 6),
                        Container(
                            height: 11,
                            color: AppColors.surface),
                        const SizedBox(height: 4),
                        Container(
                            width: 160,
                            height: 11,
                            color: AppColors.surface),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          childCount: 5,
        ),
      );

  // ── Error ────────────────────────────────────────────────────────────────
  Widget _buildErrorSliver() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: AppSpacing.iconXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load collection', style: AppTypography.subtitle1),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                ),
                child: Text('Try Again', style: AppTypography.button),
              ),
            ],
          ),
        ),
      );

  // ── Content ──────────────────────────────────────────────────────────────
  Widget _buildContentSliver(CollectionDetailModel d) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Overview
        if (d.overview.isNotEmpty) ...[
          Text(d.overview, style: AppTypography.body2),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
        ],
        // Parts count
        Row(
          children: [
            Text('Films in Collection', style: AppTypography.subtitle1),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${d.parts.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Part entries
        ...d.parts.map((p) => _PartCard(
              part: p,
              onTap: () => context.push(
                AppRouter.movieDetail,
                extra: {
                  'id': p.id,
                  'title': p.title,
                  'overview': p.overview,
                  'posterUrl': p.fullPosterUrl,
                  'backdropUrl': '',
                  'rating': p.voteAverage,
                  'releaseDate': p.releaseDate,
                },
              ),
            )),
      ]),
    );
  }
}

// ── Part Card ────────────────────────────────────────────────────────────────

class _PartCard extends StatelessWidget {
  final CollectionPart part;
  final VoidCallback onTap;

  const _PartCard({required this.part, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: part.fullPosterUrl,
                width: 80,
                height: 115,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 80,
                  height: 115,
                  color: AppColors.surfaceElevated,
                ),
                errorWidget: (_, _, _) => Container(
                  width: 80,
                  height: 115,
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.title,
                    style: AppTypography.subtitle2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  if (part.year.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs4),
                        Text(
                          part.year,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xs4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: AppColors.accent1,
                      ),
                      const SizedBox(width: AppSpacing.xs4),
                      Text(
                        part.voteAverage.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent1,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (part.overview.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      part.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: AppSpacing.iconMd,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
