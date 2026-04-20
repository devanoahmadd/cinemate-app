import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../bloc/auth_bloc/auth_bloc.dart';
import '../../../bloc/auth_bloc/auth_event.dart';
import '../../../bloc/auth_bloc/auth_state.dart';
import '../../../bloc/watchlist_bloc/watchlist_bloc.dart';
import '../../../bloc/watchlist_bloc/watchlist_event.dart';
import '../../../bloc/watchlist_bloc/watchlist_state.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/watchlist_model.dart';
import '../../../data/services/user_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _userService = UserService();
  String? _photoUrl;
  String? _displayName;

  // How many items to show in the horizontal scroll before "See All"
  static const int _watchlistPreviewLimit = 6;

  @override
  void initState() {
    super.initState();
    context.read<WatchlistBloc>().add(WatchlistLoad());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _userService.getUserProfile();
      if (mounted && data != null) {
        setState(() {
          _photoUrl = data['photoUrl'] as String?;
          _displayName = data['displayName'] as String?;
        });
      }
    } catch (_) {}
  }

  String _resolvedName(String emailFallback) =>
      (_displayName != null && _displayName!.isNotEmpty)
          ? _displayName!
          : emailFallback;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final String email = authState is AuthAuthenticated
        ? (authState.user.email ?? 'user@email.com')
        : 'user@email.com';
    final String username = _resolvedName(email.split('@').first);
    final String initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go(AppRouter.login);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.background,
            onRefresh: () async {
              context.read<WatchlistBloc>().add(WatchlistLoad());
              await _loadProfile();
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PAGE TITLE ──────────────────────────────────────
                  Padding(
                    padding: AppSpacing.hPad
                        .copyWith(top: AppSpacing.pageTopPadding),
                    child: Text('Profile', style: AppTypography.heading2),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── PROFILE HEADER ──────────────────────────────────
                  _buildProfileHeader(
                      email, username, initial),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── WATCHLIST PREVIEW ───────────────────────────────
                  _buildWatchlistSection(),

                  // ── ACCOUNT SECTION ─────────────────────────────────
                  _buildAccountSection(email, username),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── SIGN OUT ────────────────────────────────────────
                  Padding(
                    padding: AppSpacing.hPad,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Sign Out',
                        style: AppTypography.button.copyWith(
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── PROFILE HEADER ───────────────────────────────────────────────────────────
  Widget _buildProfileHeader(
      String email, String username, String initial) {
    const double avatarSize = 108.0;                         // enlarged pfp
    const double ringGap   = 3.0;                           // gap: photo → ring
    const double ringBorder = 2.5;                          // ring thickness
    const double outerSize = avatarSize + (ringGap + ringBorder) * 2; // ≈ 119
    // Camera button: padding 4px + icon 20px + border 2.5px each side = ~29px radius
    const double camHalf = 14.5;

    return Center(
      child: Column(
        children: [
          // ── Avatar stack ────────────────────────────────────────
          GestureDetector(
            onTap: () => _goEditProfile(username),
            child: SizedBox(
              // Extra bottom space so the camera button doesn't get clipped
              width: outerSize,
              height: outerSize + 16,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // 1. Outer red glow ring
                  Container(
                    width: outerSize,
                    height: outerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.55),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          blurRadius: 44,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // 2. Dark gap between ring and photo
                  Positioned(
                    top: ringBorder,
                    left: ringBorder,
                    child: Container(
                      width: outerSize - ringBorder * 2,
                      height: outerSize - ringBorder * 2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                  // 3. Avatar photo / initial
                  Positioned(
                    top: ringBorder + ringGap,
                    left: ringBorder + ringGap,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: ClipOval(
                        child: _photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Center(
                                  child: Text(initial,
                                      style: AppTypography.heading1
                                          .copyWith(fontSize: 34)),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Text(initial,
                                      style: AppTypography.heading1
                                          .copyWith(fontSize: 34)),
                                ),
                              )
                            : Center(
                                child: Text(initial,
                                    style: AppTypography.heading1
                                        .copyWith(fontSize: 34)),
                              ),
                      ),
                    ),
                  ),
                  // 4. Camera button — bottom center
                  Positioned(
                    bottom: 0,
                    left: outerSize / 2 - camHalf,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(username, style: AppTypography.greeting),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            email,
            style: AppTypography.caption
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── WATCHLIST SECTION ────────────────────────────────────────────────────────
  Widget _buildWatchlistSection() {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      buildWhen: (_, curr) =>
          curr is WatchlistLoaded ||
          curr is WatchlistLoading ||
          curr is WatchlistError,
      builder: (context, state) {
        final items =
            state is WatchlistLoaded ? state.items : <WatchlistModel>[];
        final isLoading = state is WatchlistLoading;
        final count = items.length;
        final preview = items.take(_watchlistPreviewLimit).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Text('My Watchlist', style: AppTypography.subtitle1),
                  const SizedBox(width: AppSpacing.xs),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '$count',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (count > 0)
                    GestureDetector(
                      onTap: () => context.push(AppRouter.watchlist),
                      child: Row(
                        children: [
                          Text('See All',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Content
            if (isLoading)
              _buildWatchlistSkeleton()
            else if (items.isEmpty)
              _buildWatchlistEmpty()
            else
              _buildWatchlistScroll(preview, count),

            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }

  Widget _buildWatchlistScroll(
      List<WatchlistModel> preview, int totalCount) {
    const posterW = AppSpacing.similarPosterW + 14.0; // card width
    const posterH = AppSpacing.similarPosterH + 40.0; // poster + title + rating (larger text)

    return SizedBox(
      height: posterH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: totalCount > _watchlistPreviewLimit
            ? preview.length + 1 // +1 for "See All" card
            : preview.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          if (i == preview.length) {
            // "See All" end-card
            return GestureDetector(
              onTap: () => context.push(AppRouter.watchlist),
              child: SizedBox(
                width: posterW - 10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('See All',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10)),
                  ],
                ),
              ),
            );
          }
          final item = preview[i];
          return SizedBox(
            width: posterW,
            child: _WatchlistCard(
              item: item,
              onTap: () => _navigateToDetail(context, item),
              onRemove: () => context
                  .read<WatchlistBloc>()
                  .add(WatchlistRemove(item.docId)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistEmpty() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bookmark_border_rounded,
                  size: 48, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.sm),
              Text('Your watchlist is empty',
                  style: AppTypography.subtitle2
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.xs4),
              Text(
                'Save movies and TV shows to watch later',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildWatchlistSkeleton() {
    const posterH = AppSpacing.similarPosterH + 40.0;
    return SizedBox(
      height: posterH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, _) => Container(
          width: AppSpacing.similarPosterW + 14,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  // ── ACCOUNT SECTION ──────────────────────────────────────────────────────────
  Widget _buildAccountSection(String email, String username) {
    return Padding(
      padding: AppSpacing.hPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Account', style: AppTypography.subtitle1),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                // ── Account info ──────────────────────────────
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  isFirst: true,
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Status',
                  value: 'Verified',
                  valueColor: AppColors.accent2,
                ),
                const _RowDivider(),
                _TappableRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () => _goEditProfile(username),
                ),
                const _RowDivider(),
                _TappableRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () => context.push(AppRouter.changePassword),
                ),
                // ── Visual separator before app info ──────────
                Divider(
                  height: 1,
                  thickness: 4,
                  color: AppColors.background,
                ),
                // ── App info ──────────────────────────────────
                const _InfoRow(
                  icon: Icons.movie_creation_outlined,
                  label: 'App',
                  value: 'Cinemate v1.0',
                ),
                const _RowDivider(),
                const _InfoRow(
                  icon: Icons.api_outlined,
                  label: 'API',
                  value: 'TMDB',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVIGATION HELPERS ───────────────────────────────────────────────────────
  Future<void> _goEditProfile(String username) async {
    final changed = await context.push<bool>(
      AppRouter.editProfile,
      extra: {'name': username, 'photoUrl': _photoUrl},
    );
    if (changed == true) await _loadProfile();
  }

  void _navigateToDetail(BuildContext context, WatchlistModel item) {
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: AppTypography.subtitle1),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.body2
              .copyWith(color: AppColors.textTertiary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.link
                    .copyWith(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuthBloc>()
                  .add(AuthLogoutRequested());
            },
            child:
                Text('Sign out', style: AppTypography.link),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WATCHLIST CARD (horizontal scroll variant)
// ─────────────────────────────────────────────────────────────────────────────
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
                        color: AppColors.overlay
                            .withValues(alpha: 0.75),
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
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW (static, non-tappable)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        isFirst ? AppSpacing.md : AppSpacing.sm,
        AppSpacing.md,
        isLast ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAPPABLE ROW (navigates somewhere)
// ─────────────────────────────────────────────────────────────────────────────
class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDisabled, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
