import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/watchlist_bloc/watchlist_bloc.dart';
import '../../bloc/watchlist_bloc/watchlist_event.dart';
import '../../bloc/watchlist_bloc/watchlist_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/watchlist_model.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  // 0 = All, 1 = Movies, 2 = TV
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    context.read<WatchlistBloc>().add(WatchlistLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('My Watchlist', style: AppTypography.subtitle1),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: BlocBuilder<WatchlistBloc, WatchlistState>(
              buildWhen: (_, s) =>
                  s is WatchlistLoaded ||
                  s is WatchlistLoading ||
                  s is WatchlistError,
              builder: (context, state) {
                if (state is WatchlistLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                if (state is WatchlistError) {
                  return Center(
                    child: Text(state.message,
                        style: AppTypography.body2
                            .copyWith(color: AppColors.textTertiary)),
                  );
                }
                final all =
                    state is WatchlistLoaded ? state.items : <WatchlistModel>[];
                final items = _filter == 0
                    ? all
                    : _filter == 1
                        ? all.where((e) => e.isMovie).toList()
                        : all.where((e) => !e.isMovie).toList();

                if (items.isEmpty) return _buildEmpty();
                return _buildGrid(items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const labels = ['All', 'Movies', 'TV'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _filter == i;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _filter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryMuted
                      : AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: AppTypography.caption.copyWith(
                    color: active
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<WatchlistModel> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, i) => _WatchlistCard(
        item: items[i],
        onTap: () => _navigateToDetail(items[i]),
        onRemove: () =>
            context.read<WatchlistBloc>().add(WatchlistRemove(items[i].docId)),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _filter == 0
                  ? 'Your watchlist is empty'
                  : _filter == 1
                      ? 'No movies saved'
                      : 'No TV shows saved',
              style: AppTypography.subtitle2
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Tap the bookmark icon on any title to save it',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textDisabled),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _navigateToDetail(WatchlistModel item) {
    if (item.isMovie) {
      context.push(AppRouter.movieDetail, extra: {
        'id': item.id,
        'title': item.title,
        'overview': '',
        'posterUrl': item.posterUrl,
        'backdropUrl': item.backdropUrl,
        'rating': item.rating,
        'releaseDate': item.releaseDate ?? '',
      });
    } else {
      context.push(AppRouter.tvDetail, extra: {
        'id': item.id,
        'name': item.title,
        'overview': '',
        'posterUrl': item.posterUrl,
        'backdropUrl': item.backdropUrl,
        'rating': item.rating,
        'firstAirDate': item.firstAirDate ?? '',
      });
    }
  }
}

class _WatchlistCard extends StatelessWidget {
  final WatchlistModel item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchlistCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.textDisabled),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isMovie
                          ? AppColors.primary.withValues(alpha: 0.9)
                          : AppColors.accent2.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs - 1),
                    ),
                    child: Text(
                      item.isMovie ? 'MOVIE' : 'TV',
                      style: AppTypography.overline.copyWith(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.overlay.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.3),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.accent1, size: 11),
              const SizedBox(width: 2),
              Text(
                item.rating.toStringAsFixed(1),
                style: AppTypography.caption.copyWith(
                    color: AppColors.accent1,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              if (item.displayDate.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  item.displayDate,
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
