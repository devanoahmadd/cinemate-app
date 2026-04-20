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
import '../../data/models/review_model.dart';
import '../../data/models/tv_detail_model.dart';
import '../../data/models/tv_model.dart';
import '../../data/models/watch_provider_model.dart';
import '../../data/models/watchlist_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/video_model.dart';
import '../../data/services/tv_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TvDetailScreen extends StatefulWidget {
  /// Basic data passed from the list/search screen via GoRouter extra.
  /// Used to show the backdrop immediately while full data is loading.
  final Map<String, dynamic> show;

  const TvDetailScreen({super.key, required this.show});

  @override
  State<TvDetailScreen> createState() => _TvDetailScreenState();
}

class _TvDetailScreenState extends State<TvDetailScreen> {
  final _service = TvService();

  // ── State: data & loading ─────────────────────────────────────────────────
  bool _isLoading = true;
  bool _hasError  = false;

  TvDetailModel?           _detailData;
  List<CastModel>          _castData       = [];
  List<ReviewModel>        _reviewData     = [];
  List<TvModel>            _similarData    = [];
  List<TvModel>            _recommendData  = [];
  List<WatchProviderModel> _watchProviders = [];
  List<VideoModel>         _videoData      = [];

  // ── State: UI-only ────────────────────────────────────────────────────────
  final _expandedNotifier = ValueNotifier<bool>(false);
  bool _isSaved = false;
  bool _watchlistCheckDone = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAllData();
    final id = widget.show['id'] as int;
    context.read<WatchlistBloc>().add(WatchlistCheckItem('tv_$id'));
  }

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final id = widget.show['id'] as int;
    try {
      // Launch all requests in parallel before awaiting any.
      final fDetail    = _service.getTvDetailFull(id);
      final fCredits   = _service.getTvCredits(id);
      final fReviews   = _service.getTvReviews(id);
      final fSimilar   = _service.getTvSimilar(id);
      final fRecommend = _service.getTvRecommendations(id);
      final fProviders = _service.getTvWatchProviders(id);
      final fVideos    = _service.getTvVideos(id);

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
        const SnackBar(content: Text('No trailer available for this show')),
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
    final id   = widget.show['id'] as int;
    final name = widget.show['name'] as String? ?? '';
    final year = () {
      final d = widget.show['firstAirDate'] as String? ?? '';
      return d.length >= 4 ? d.substring(0, 4) : '';
    }();
    final rating    = widget.show['rating'] as num?;
    final ratingStr = rating != null ? rating.toStringAsFixed(1) : '';

    final text = [
      '📺 $name${year.isNotEmpty ? ' ($year)' : ''}',
      if (ratingStr.isNotEmpty) '⭐ $ratingStr/10 · TMDB',
      '',
      'https://www.themoviedb.org/tv/$id',
    ].join('\n');

    SharePlus.instance.share(ShareParams(text: text));
  }

  void _toggleWatchlist() {
    final id    = widget.show['id'] as int;
    final docId = 'tv_$id';
    final bloc  = context.read<WatchlistBloc>();
    if (_isSaved) {
      bloc.add(WatchlistRemove(docId));
    } else {
      bloc.add(WatchlistAdd(WatchlistModel(
        id:           id,
        mediaType:    'tv',
        title:        widget.show['name']        as String,
        posterUrl:    widget.show['posterUrl']   as String,
        backdropUrl:  widget.show['backdropUrl'] as String,
        rating:       (widget.show['rating']     as num).toDouble(),
        addedAt:      DateTime.now(),
        firstAirDate: widget.show['firstAirDate'] as String?,
      )));
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  /// Color-coded by airing status.
  /// accent2 (teal) = active/ongoing, error (red) = canceled,
  /// accent1 (gold) = planned, textDisabled = ended.
  Color? _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returning series':
      case 'in production':
        return AppColors.accent2;
      case 'canceled':
        return AppColors.error;
      case 'planned':
        return AppColors.accent1;
      case 'ended':
        return AppColors.textDisabled;
      default:
        return null;
    }
  }

  /// Short label for the backdrop badge (keeps the badge compact).
  String _statusShort(String status) {
    switch (status.toLowerCase()) {
      case 'returning series': return 'Returning';
      case 'in production':    return 'In Prod.';
      case 'ended':            return 'Ended';
      case 'canceled':         return 'Canceled';
      case 'planned':          return 'Planned';
      default:                 return status;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;

    final docId = 'tv_${widget.show['id']}';

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
                    imageUrl: widget.show['backdropUrl'] ?? '',
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
                  // Status badge — shown once detail data arrives
                  if (_detailData != null && _detailData!.status.isNotEmpty)
                    Positioned(
                      top: statusBarH + 10,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (_statusColor(_detailData!.status) ?? AppColors.primary)
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          _statusShort(_detailData!.status),
                          style: AppTypography.overline.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
          // Show info 2×2 grid
          Row(children: [
            Expanded(child: _shimBox(height: 56)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: _shimBox(height: 56)),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Expanded(child: _shimBox(height: 56)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: _shimBox(height: 56)),
          ]),
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
  Widget _buildContent(TvDetailModel d) {
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
        const SizedBox(height: AppSpacing.md),
        _buildActionButtons(),
        _divider(),
        _buildSynopsis(d.overview),
        _divider(),
        _buildShowInfo(d),
        if (d.seasons.isNotEmpty) ...[
          _divider(),
          _buildSeasons(d),
        ],
        if (d.networks.isNotEmpty) ...[
          _divider(),
          _buildNetworks(d.networks),
        ],
        if (_castData.isNotEmpty) ...[
          _divider(),
          _buildCast(),
        ],
        _divider(),
        _buildReviews(d),
        if (d.productionCompanies.isNotEmpty) ...[
          _divider(),
          _buildProduction(d.productionCompanies),
        ],
        if (_watchProviders.isNotEmpty) ...[
          _divider(),
          _buildWatchProviders(),
        ],
        if (_similarData.isNotEmpty) ...[
          _divider(),
          _buildHorizontalShowRow('Similar Shows', _similarData),
        ],
        if (_recommendData.isNotEmpty) ...[
          _divider(),
          _buildHorizontalShowRow('Recommendations', _recommendData),
        ],
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

  Widget _infoCard(String label, String value, {Color? valueColor}) => Container(
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
              style: AppTypography.subtitle2.copyWith(color: valueColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: HERO ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroRow(TvDetailModel d) {
    final langIso = d.originalLanguage.toUpperCase();
    final langName = d.spokenLanguages.isNotEmpty
        ? d.spokenLanguages.first.englishName
        : langIso;

    final dateStr = d.formattedFirstAirDate.isNotEmpty
        ? d.formattedFirstAirDate
        : '—';
    final rangeStr = d.airRange.isNotEmpty ? ' · ${d.airRange}' : '';

    final rtStr = d.formattedEpisodeRunTime.isNotEmpty
        ? d.formattedEpisodeRunTime
        : '—';
    final seasonsStr = d.numberOfSeasons > 0
        ? ' · ${d.numberOfSeasons} Season${d.numberOfSeasons > 1 ? 's' : ''}'
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Poster ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: CachedNetworkImage(
              imageUrl: widget.show['posterUrl'] ?? '',
              width: AppSpacing.detailPosterW,
              height: AppSpacing.detailPosterH,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                width: AppSpacing.detailPosterW,
                height: AppSpacing.detailPosterH,
                color: AppColors.surface,
              ),
              errorWidget: (_, _, _) => Container(
                width: AppSpacing.detailPosterW,
                height: AppSpacing.detailPosterH,
                color: AppColors.surface,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // ── Info column — fixed height = poster height.
        // spaceBetween with 5 items: gaps scale with title length.
        Expanded(
          child: SizedBox(
            height: AppSpacing.detailPosterH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  d.name,
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

                // First air date + air range
                _metaRow(
                  Icons.calendar_today_rounded,
                  Flexible(
                    child: Text(
                      '$dateStr$rangeStr',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Episode runtime + season count — aligns to poster bottom
                _metaRow(
                  Icons.schedule_rounded,
                  Text(
                    '$rtStr$seasonsStr',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
              label: Text(
                'Watch Trailer',
                style: AppTypography.button.copyWith(fontSize: 13),
              ),
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
          _iconActionBtn(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_rounded,
            _toggleWatchlist,
          ),
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
  // SECTION: SHOW INFO  (replaces Financials — TV has no budget/revenue)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildShowInfo(TvDetailModel d) {
    final statusColor = _statusColor(d.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Show Info', style: AppTypography.subtitle1),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                'SEASONS',
                d.numberOfSeasons > 0 ? d.numberOfSeasons.toString() : '—',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _infoCard(
                'EPISODES',
                d.numberOfEpisodes > 0 ? d.numberOfEpisodes.toString() : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                'STATUS',
                d.status.isNotEmpty ? d.status : '—',
                valueColor: statusColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _infoCard(
                'TYPE',
                d.type.isNotEmpty ? d.type : '—',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: SEASONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSeasons(TvDetailModel d) {
    // Regular seasons first, Specials (season_number == 0) last.
    final regular  = d.seasons.where((s) => !s.isSpecials).toList();
    final specials = d.seasons.where((s) => s.isSpecials).toList();
    final sorted   = [...regular, ...specials];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Seasons'),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppSpacing.similarPosterH + 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.xs + 1),
            itemBuilder: (context, i) {
              final s = sorted[i];
              // Fall back to show poster when season has none.
              final posterUrl = s.fullPosterUrl.isNotEmpty
                  ? s.fullPosterUrl
                  : widget.show['posterUrl'] ?? '';

              return SizedBox(
                width: AppSpacing.similarPosterW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Poster with overlay badges ──────────────────────
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd - 2,
                          ),
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
                        // Episode count — bottom-right
                        if (s.episodeCount > 0)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.overlay.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXs - 2,
                                ),
                              ),
                              child: Text(
                                '${s.episodeCount} ep',
                                style: AppTypography.overline.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        // "SPECIALS" label — top-left
                        if (s.isSpecials)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent1.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXs - 2,
                                ),
                              ),
                              child: Text(
                                'SPECIALS',
                                style: AppTypography.overline.copyWith(
                                  color: AppColors.background,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (s.airYear.isNotEmpty)
                      Text(
                        s.airYear,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 9,
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: NETWORKS (Netflix, HBO, BBC, etc.)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNetworks(List<TvNetwork> networks) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Networks', style: AppTypography.subtitle1),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: networks.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final n = networks[i];
                return Container(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (n.logoPath.isNotEmpty)
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            maxWidth: 80,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs4,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXs - 2,
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: n.fullLogoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) =>
                                const SizedBox(width: 32),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.tv_rounded,
                              size: 16,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.tv_rounded,
                          size: 18,
                          color: AppColors.textDisabled,
                        ),
                      const SizedBox(height: AppSpacing.xs4),
                      Text(
                        n.name,
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
  // SECTION: CAST
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCast() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Main Cast'),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: AppSpacing.castAvatarSize + 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _castData.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final c = _castData[i];
                return SizedBox(
                  width: 60,
                  child: Column(
                    children: [
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

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: REVIEWS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReviews(TvDetailModel d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('User Reviews'),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _ReviewCard(review: r),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (c.logoPath.isNotEmpty)
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            maxWidth: 80,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs4,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXs - 2,
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: c.fullLogoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) =>
                                const SizedBox(width: 32),
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
  // SECTION: HORIZONTAL SHOW ROW  (similar & recommendations)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHorizontalShowRow(String title, List<TvModel> shows) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: AppSpacing.similarPosterH + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shows.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs + 1),
              itemBuilder: (context, i) {
                final s = shows[i];
                return GestureDetector(
                  onTap: () => context.push(
                    AppRouter.tvDetail,
                    extra: {
                      'id':           s.id,
                      'name':         s.name,
                      'overview':     s.overview,
                      'posterUrl':    s.fullPosterUrl,
                      'backdropUrl':  s.fullBackdropUrl,
                      'rating':       s.voteAverage,
                      'firstAirDate': s.firstAirDate,
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
                            imageUrl: s.fullPosterUrl,
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
                          s.displayTitle,
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
                              s.voteAverage.toStringAsFixed(1),
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

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGET: REVIEW CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

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
                    // Review text — indented past the avatar
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
