import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/watchlist_bloc/watchlist_bloc.dart';
import '../../bloc/watchlist_bloc/watchlist_event.dart';
import '../../bloc/watchlist_bloc/watchlist_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/cast_model.dart';
import '../../data/models/movie_detail_model.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/watch_provider_model.dart';
import '../../data/models/watchlist_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/video_model.dart';
import '../../data/services/movie_service.dart';
import '../../screens/movie/media_related_screen.dart';
import '../../widgets/review_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MovieDetailScreen extends StatefulWidget {
  /// Basic data passed from the list/search screen via GoRouter extra.
  /// Used to show the backdrop immediately while full data is loading.
  final Map<String, dynamic> movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _service = MovieService();

  // ── State: data & loading ─────────────────────────────────────────────────
  // Only data-fetch results and loading/error flags live here.
  // setState on these is intentional — they replace the entire body skeleton
  // with real content, which is a one-time event per screen visit.
  bool _isLoading = true;
  bool _hasError  = false;

  MovieDetailModel?        _detailData;
  List<CastModel>          _castData       = [];
  List<ReviewModel>        _reviewData     = [];
  List<MovieModel>         _similarData    = [];
  List<MovieModel>         _recommendData  = [];
  List<WatchProviderModel> _watchProviders = [];
  List<VideoModel>         _videoData      = [];

  // ── State: UI-only ────────────────────────────────────────────────────────
  final _expandedNotifier = ValueNotifier<bool>(false);
  bool _isSaved = false;
  bool _watchlistCheckDone = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAllData();
    final id = widget.movie['id'] as int;
    context.read<WatchlistBloc>().add(WatchlistCheckItem('movie_$id'));
  }

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final id = widget.movie['id'] as int;
    try {
      // Launch all requests in parallel before awaiting any.
      final fDetail    = _service.getMovieDetailFull(id);
      final fCredits   = _service.getMovieCredits(id);
      final fReviews   = _service.getMovieReviews(id);
      final fSimilar   = _service.getMovieSimilar(id);
      final fRecommend = _service.getMovieRecommendations(id);
      final fProviders = _service.getMovieWatchProviders(id);
      final fVideos    = _service.getMovieVideos(id);

      _detailData     = await fDetail;
      _castData       = await fCredits;
      _reviewData     = await fReviews;
      _similarData    = await fSimilar;
      _recommendData  = await fRecommend;
      _watchProviders = await fProviders;
      _videoData      = await fVideos;

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _retry() {
    _expandedNotifier.value = false;
    setState(() { _isLoading = true; _hasError = false; });
    _loadAllData();
  }

  // ── Button handlers ────────────────────────────────────────────────────────
  Future<void> _onTrailer() async {
    final trailer = pickBestTrailer(_videoData);
    if (trailer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trailer available for this movie')),
      );
      return;
    }
    final uri = Uri.parse(trailer.youtubeUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube')),
      );
    }
  }

  void _onShare() {
    final id    = widget.movie['id'] as int;
    final title = widget.movie['title'] as String? ?? '';
    final year  = () {
      final d = widget.movie['releaseDate'] as String? ?? '';
      return d.length >= 4 ? d.substring(0, 4) : '';
    }();
    final rating = widget.movie['rating'] as num?;
    final ratingStr = rating != null ? rating.toStringAsFixed(1) : '';

    final text = [
      '🎬 $title${year.isNotEmpty ? ' ($year)' : ''}',
      if (ratingStr.isNotEmpty) '⭐ $ratingStr/10 · TMDB',
      '',
      'https://www.themoviedb.org/movie/$id',
    ].join('\n');

    SharePlus.instance.share(ShareParams(text: text));
  }

  void _toggleWatchlist() {
    final id    = widget.movie['id'] as int;
    final docId = 'movie_$id';
    final bloc  = context.read<WatchlistBloc>();
    if (_isSaved) {
      bloc.add(WatchlistRemove(docId));
    } else {
      bloc.add(WatchlistAdd(WatchlistModel(
        id:          id,
        mediaType:   'movie',
        title:       widget.movie['title']       as String,
        posterUrl:   widget.movie['posterUrl']   as String,
        backdropUrl: widget.movie['backdropUrl'] as String,
        rating:      (widget.movie['rating']     as num).toDouble(),
        addedAt:     DateTime.now(),
        releaseDate: widget.movie['releaseDate'] as String?,
      )));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;

    final docId = 'movie_${widget.movie['id']}';

    return BlocListener<WatchlistBloc, WatchlistState>(
      listener: (context, state) {
        if (state is WatchlistItemStatus && state.docId == docId) {
          setState(() => _isSaved = state.isSaved);
          if (_watchlistCheckDone) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                state.isSaved ? 'Saved to watchlist' : 'Removed from watchlist',
              ),
              duration: const Duration(seconds: 2),
            ));
          } else {
            _watchlistCheckDone = true;
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ── BACKDROP APP BAR ────────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: AppSpacing.detailAppBarHeight,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            // Back button always visible (survives AppBar collapse)
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
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  CachedNetworkImage(
                    imageUrl: widget.movie['backdropUrl'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(color: AppColors.surface),
                  ),
                  // Gradient fade to background
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppShadows.detailAppBarGradient,
                    ),
                  ),
                  // 18+ badge — only when adult == true
                  if (_detailData?.adult == true)
                    Positioned(
                      top: statusBarH + 10,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text('18+', style: AppTypography.overline),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── BODY ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: _isLoading
                  ? _buildSkeleton()
                  : _hasError
                      ? _buildError()
                      : _buildContent(_detailData!),
            ),
          ),
        ],
      ),
      ), // Scaffold
    );   // BlocListener
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SKELETON (shimmer loading)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero row skeleton
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimBox(width: AppSpacing.detailPosterW, height: AppSpacing.detailPosterH),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimBox(height: 18),
                    const SizedBox(height: AppSpacing.xs),
                    _shimBox(width: 130, height: 12),
                    const SizedBox(height: AppSpacing.xs),
                    _shimBox(width: 100, height: 12),
                    const SizedBox(height: AppSpacing.xs),
                    _shimBox(width: 110, height: 12),
                    const SizedBox(height: AppSpacing.xs),
                    _shimBox(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _shimBox(height: 36), // tagline
          const SizedBox(height: AppSpacing.sm),
          // Genre pills
          Row(children: [
            _shimBox(width: 72, height: 22),
            const SizedBox(width: AppSpacing.xs),
            _shimBox(width: 60, height: 22),
            const SizedBox(width: AppSpacing.xs),
            _shimBox(width: 52, height: 22),
          ]),
          const SizedBox(height: AppSpacing.md),
          _shimBox(height: 42), // action buttons
          const SizedBox(height: AppSpacing.xl),
          _shimBox(width: 80, height: 14),  // section label
          const SizedBox(height: AppSpacing.xs),
          _shimBox(height: 14),
          const SizedBox(height: 4),
          _shimBox(height: 14),
          const SizedBox(height: 4),
          _shimBox(width: 200, height: 14),
          const SizedBox(height: AppSpacing.xl),
          _shimBox(width: 80, height: 14),
          const SizedBox(height: AppSpacing.xs),
          _shimBox(height: 70),
        ],
      ),
    );
  }

  Widget _shimBox({double? width, required double height}) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildError() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: AppSpacing.iconXl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load data', style: AppTypography.subtitle1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check your internet connection',
            style: AppTypography.body2.copyWith(color: AppColors.textTertiary),
          ),
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
      );

  // ─────────────────────────────────────────────────────────────────────────
  // FULL CONTENT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContent(MovieDetailModel d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroRow(d),
        if (d.tagline.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTagline(d.tagline),
        ],
        if (d.genres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildGenrePills(d.genres),
        ],
        if (d.status.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildStatusPill(d.status),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildActionButtons(),
        _divider(),
        _buildSynopsis(d.overview),
        _divider(),
        if (d.belongsToCollection != null) ...[
          _buildCollection(d.belongsToCollection!),
          _divider(),
        ],
        _buildFinancials(d),
        _divider(),
        if (_castData.isNotEmpty) ...[
          _buildCast(),
          _divider(),
        ],
        _buildReviews(d),
        _divider(),
        if (d.productionCompanies.isNotEmpty) ...[
          _buildProduction(d.productionCompanies),
          _divider(),
        ],
        if (_watchProviders.isNotEmpty) ...[
          _buildWatchProviders(),
          _divider(),
        ],
        if (_similarData.isNotEmpty) ...[
          _buildHorizontalMovieRow(
            'Similar Movies',
            _similarData,
            onSeeAll: _similarData.length >= 20
                ? () => context.push(AppRouter.relatedAll, extra: {
                      'movieId':      widget.movie['id'] as int,
                      'movieTitle':   _detailData!.title,
                      'type':         MediaRelatedType.similar,
                      'initialMovies': _similarData,
                    })
                : null,
          ),
          _divider(),
        ],
        if (_recommendData.isNotEmpty)
          _buildHorizontalMovieRow(
            'Recommendations',
            _recommendData,
            onSeeAll: _recommendData.length >= 20
                ? () => context.push(AppRouter.relatedAll, extra: {
                      'movieId':      widget.movie['id'] as int,
                      'movieTitle':   _detailData!.title,
                      'type':         MediaRelatedType.recommendations,
                      'initialMovies': _recommendData,
                    })
                : null,
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Divider(color: AppColors.divider, height: 1),
      );

  Widget _sectionTitle(String text, {VoidCallback? onSeeAll}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: AppTypography.subtitle1),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text('See All', style: AppTypography.link),
            ),
        ],
      );

  /// Aligned icon + content row used for every meta datum in the hero section.
  Widget _metaRow(IconData icon, Widget child) => Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Icon(icon, size: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 4),
          child,
        ],
      );

  Widget _buildStarRow(double voteAverage) {
    final filled = (voteAverage / 2).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star_rounded,
          size: 11,
          color: i < filled
              ? AppColors.accent1
              : AppColors.accent1.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _watchlistBtn() => GestureDetector(
        onTap: _toggleWatchlist,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _isSaved ? AppColors.primaryMuted : AppColors.surface,
            borderRadius: AppSpacing.buttonRadius,
            border: Border.all(
              color: _isSaved ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Icon(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            color: _isSaved ? AppColors.primary : AppColors.textSecondary,
            size: AppSpacing.iconMd,
          ),
        ),
      );

  Widget _iconActionBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.buttonRadius,
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: AppSpacing.iconMd,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Maps a TMDB status string to its display color, icon, and label.
  ({Color color, IconData icon, String label}) _statusConfig(String status) =>
      switch (status) {
        'Released' => (
            color: AppColors.statusReleased,
            icon: Icons.check_circle_outline_rounded,
            label: 'Released',
          ),
        'In Production' => (
            color: AppColors.statusInProgress,
            icon: Icons.movie_creation_outlined,
            label: 'In Production',
          ),
        'Post Production' => (
            color: AppColors.statusInProgress,
            icon: Icons.cut_rounded,
            label: 'Post Production',
          ),
        'Planned' => (
            color: AppColors.statusNeutral,
            icon: Icons.event_note_outlined,
            label: 'Planned',
          ),
        'Rumored' => (
            color: AppColors.statusNeutral,
            icon: Icons.help_outline_rounded,
            label: 'Rumored',
          ),
        'Canceled' => (
            color: AppColors.error,
            icon: Icons.cancel_outlined,
            label: 'Canceled',
          ),
        _ => (
            color: AppColors.statusNeutral,
            icon: Icons.info_outline_rounded,
            label: status,
          ),
      };

  /// Pill chip (Option B) — shown below genre pills for all statuses.
  Widget _buildStatusPill(String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    final cfg = _statusConfig(status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 5),
          decoration: BoxDecoration(
            color: cfg.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: cfg.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cfg.icon, size: 13, color: cfg.color),
              const SizedBox(width: AppSpacing.xs4),
              Text(
                cfg.label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cfg.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mini badge (Option C) — bottom-left corner of the poster thumbnail.
  /// Uses rounded corners that match the poster's bottom-left radius.
  Widget _buildPosterBadge(String status) {
    final cfg = _statusConfig(status);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppSpacing.radiusMd),
        topRight:   Radius.circular(AppSpacing.radiusXs),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        color: cfg.color.withValues(alpha: 0.88),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cfg.icon, size: 8, color: AppColors.textPrimary),
            const SizedBox(width: 3),
            Text(
              cfg.label,
              style: AppTypography.overline.copyWith(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financialCard(String label, String value, {Color? valueColor}) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              value,
              style: AppTypography.subtitle2.copyWith(
                color: valueColor,
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: HERO ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroRow(MovieDetailModel d) {
    // Primary spoken language display
    final langIso = d.originalLanguage.toUpperCase();
    final langName = d.spokenLanguages.isNotEmpty
        ? d.spokenLanguages.first.englishName
        : langIso;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Poster ──────────────────────────────────────────────
        SizedBox(
          width: AppSpacing.detailPosterW,
          height: AppSpacing.detailPosterH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: widget.movie['posterUrl'] ?? '',
                    width: AppSpacing.detailPosterW,
                    height: AppSpacing.detailPosterH,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.surface,
                    ),
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
              // Status badge (C) — bottom-left, only for non-Released
              if (_detailData != null &&
                  _detailData!.status.isNotEmpty &&
                  _detailData!.status != 'Released')
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildPosterBadge(_detailData!.status),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // ── Info column — fixed height = poster height.
        // spaceBetween with 5 items: gaps scale with title length,
        // so short titles (~15px gap) and long titles (~5px gap) both look balanced.
        Expanded(
          child: SizedBox(
            height: AppSpacing.detailPosterH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  d.title,
                  style: AppTypography.heading3,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // ★ score · votes
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent1,
                      size: 12,
                    ),
                    const SizedBox(width: AppSpacing.xs4),
                    Text(
                      d.voteAverage.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accent1,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs4,
                      ),
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textDisabled,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '${_formatCount(d.voteCount)} votes',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                // Language
                _metaRow(
                  Icons.language_rounded,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs - 2,
                          ),
                        ),
                        child: Text(
                          langIso,
                          style: AppTypography.overline.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 8,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs4),
                      Text(
                        langName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Release date
                _metaRow(
                  Icons.calendar_today_rounded,
                  Text(
                    d.formattedReleaseDate,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Runtime — last item, aligns to poster bottom
                _metaRow(
                  Icons.schedule_rounded,
                  Text(
                    d.formattedRuntime.isNotEmpty ? d.formattedRuntime : '—',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: TAGLINE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTagline(String tagline) => Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 2.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs4,
        ),
        child: Text(
          '"$tagline"',
          style: AppTypography.body2.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textTertiary,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: GENRE PILLS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGenrePills(List<MovieGenre> genres) => Wrap(
        spacing: AppSpacing.xs - 2,
        runSpacing: AppSpacing.xs - 2,
        children: genres
            .map(
              (g) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 1,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  g.name,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            )
            .toList(),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: ACTION BUTTONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _onTrailer,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: Text('Watch Trailer', style: AppTypography.button.copyWith(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shadowColor: AppColors.primaryGlow,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonRadius,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _watchlistBtn(),
          const SizedBox(width: AppSpacing.xs),
          _iconActionBtn(Icons.share_outlined, _onShare),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: SYNOPSIS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSynopsis(String overview) {
    final text = overview.isNotEmpty ? overview : 'No synopsis available.';
    final isLong = overview.length > 200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: AppTypography.subtitle1),
        const SizedBox(height: AppSpacing.xs),
        // ValueListenableBuilder isolates rebuild to this subtree only.
        // Tapping "Baca selengkapnya" no longer triggers a full content rebuild.
        ValueListenableBuilder<bool>(
          valueListenable: _expandedNotifier,
          builder: (_, expanded, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: expanded ? null : 3,
                overflow:
                    expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: AppTypography.body2,
              ),
              if (isLong)
                GestureDetector(
                  onTap: () =>
                      _expandedNotifier.value = !_expandedNotifier.value,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs4),
                    child: Text(
                      expanded ? 'Less' : 'Read more',
                      style: AppTypography.link,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: COLLECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCollection(CollectionInfo c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Part of Collection', style: AppTypography.subtitle1),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => context.push(
              AppRouter.collection,
              extra: {
                'collectionId':   c.id,
                'collectionName': c.name,
              },
            ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Mini poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  child: CachedNetworkImage(
                    imageUrl: c.fullPosterUrl,
                    width: 36,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 36,
                      height: 52,
                      color: AppColors.surfaceElevated,
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 36,
                      height: 52,
                      color: AppColors.surfaceElevated,
                      child: const Icon(
                        Icons.movie_rounded,
                        color: AppColors.textDisabled,
                        size: 14,
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
                        'FILM COLLECTION',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(c.name, style: AppTypography.subtitle2),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withValues(alpha: 0.5),
                  size: AppSpacing.iconMd,
                ),
              ],
            ),
          ),
          ), // GestureDetector
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: FINANCIALS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFinancials(MovieDetailModel d) {
    final hasBoth = d.budget > 0 && d.revenue > 0;
    final revenueColor = hasBoth
        ? (d.revenue > d.budget ? AppColors.accent2 : AppColors.error)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financials', style: AppTypography.subtitle1),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _financialCard(
                'BUDGET',
                d.formattedBudget.isNotEmpty ? d.formattedBudget : 'N/A',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _financialCard(
                'REVENUE',
                d.formattedRevenue.isNotEmpty ? d.formattedRevenue : 'N/A',
                valueColor: revenueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: CAST
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCast() {
    final preview = _castData.take(20).toList();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Main Cast',
            onSeeAll: _castData.length > 20
                ? () => context.push(AppRouter.castAll, extra: {
                      'movieTitle': _detailData!.title,
                      'cast':       _castData,
                    })
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            // avatar + name (2 lines max ~26px) + character (~13px) + gaps
            height: AppSpacing.castAvatarSize + 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final c = preview[i];
                return SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      // Avatar
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: c.fullProfileUrl,
                          width: AppSpacing.castAvatarSize,
                          height: AppSpacing.castAvatarSize,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AppColors.surfaceElevated,
                            width: AppSpacing.castAvatarSize,
                            height: AppSpacing.castAvatarSize,
                            alignment: Alignment.center,
                            child: Text(
                              c.initials,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceElevated,
                            width: AppSpacing.castAvatarSize,
                            height: AppSpacing.castAvatarSize,
                            alignment: Alignment.center,
                            child: Text(
                              c.initials,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        c.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        c.character,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 8,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
  } // _buildCast

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: REVIEWS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReviews(MovieDetailModel d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'User Reviews',
            onSeeAll: _reviewData.isNotEmpty
                ? () => context.push(AppRouter.reviewsAll, extra: {
                      'movieId':        widget.movie['id'] as int,
                      'movieTitle':     d.title,
                      'voteAverage':    d.voteAverage,
                      'voteCount':      d.voteCount,
                      'initialReviews': _reviewData,
                    })
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Summary bar
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
                      d.voteAverage.toStringAsFixed(1),
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
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRow(d.voteAverage),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      '${_formatCount(d.voteCount)} votes',
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

          // Review cards (max 3)
          if (_reviewData.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ..._reviewData.take(3).map(
                  (r) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ReviewCard(review: r),
                  ),
                ),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No user reviews yet.',
              style: AppTypography.body2.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: PRODUCTION COMPANIES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProduction(List<ProductionCompany> companies) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production Companies', style: AppTypography.subtitle1),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: companies.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final c = companies[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (c.logoPath.isNotEmpty)
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(minWidth: 40, maxWidth: 80),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs4,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs - 2),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: c.fullLogoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const SizedBox(width: 32),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.movie_rounded,
                              size: 16,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.movie_rounded,
                          size: 18,
                          color: AppColors.textDisabled,
                        ),
                      const SizedBox(height: AppSpacing.xs4),
                      Text(
                        c.name,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: WATCH PROVIDERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWatchProviders() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available On', style: AppTypography.subtitle1),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs - 1,
            runSpacing: AppSpacing.xs - 1,
            children: _watchProviders
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm - 1,
                      vertical: AppSpacing.xs - 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm + 1),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.logoPath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: p.fullLogoUrl,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: AppSpacing.xs4),
                        Text(
                          p.providerName,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: HORIZONTAL MOVIE ROW  (similar & recommendations)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHorizontalMovieRow(
    String title,
    List<MovieModel> movies, {
    VoidCallback? onSeeAll,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, onSeeAll: onSeeAll),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            // poster + title (1 line) + rating — allow ~32px below poster
            height: AppSpacing.similarPosterH + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs + 1),
              itemBuilder: (context, i) {
                final m = movies[i];
                return GestureDetector(
                  onTap: () => context.push(
                    AppRouter.movieDetail,
                    extra: {
                      'id': m.id,
                      'title': m.title,
                      'overview': m.overview,
                      'posterUrl': m.fullPosterUrl,
                      'backdropUrl': m.fullBackdropUrl,
                      'rating': m.voteAverage,
                      'releaseDate': m.releaseDate,
                    },
                  ),
                  child: SizedBox(
                    width: AppSpacing.similarPosterW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd - 2,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: m.fullPosterUrl,
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
                          m.title,
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
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent1,
                              size: 9,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              m.voteAverage.toStringAsFixed(1),
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
          ),
        ],
      );
}

