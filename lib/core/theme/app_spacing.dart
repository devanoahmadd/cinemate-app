import 'package:flutter/material.dart';

/// Centralized spacing & radius system for Cinemate.
///
/// SYSTEM: 8px base grid
///   All spacing values are multiples of 4px (half-grid) or 8px (full-grid).
///   This ensures visual rhythm and predictable alignment across screens.
///
/// CATEGORIES:
///   Space    → xs4, xs, sm, md, lg, xl, xxl  (margins & padding)
///   Radius   → radiusXs → radiusFull         (border radius)
///   Layout   → pageH, pageV, pagePad         (standard page margins)
///   Component → icon sizes, avatar, thumbnail, banner heights
///
/// USAGE:
///   padding: EdgeInsets.all(AppSpacing.md)
///   padding: AppSpacing.pagePad
///   borderRadius: BorderRadius.circular(AppSpacing.radiusMd)
///   SizedBox(height: AppSpacing.lg)
///
/// RULES:
///   - NEVER hard-code spacing numbers in widget files
///   - Use .copyWith() or EdgeInsets variants to compose compound padding
///   - For responsive spacing, multiply base values — do NOT invent new values
abstract class AppSpacing {
  AppSpacing._(); // prevents instantiation

  // ============================================================
  // SPACING SCALE (8px grid)
  // ============================================================

  /// 4px — micro gap, icon-to-text spacing within a Row.
  static const double xs4 = 4.0;

  /// 8px — tight spacing, between badge elements, small gaps.
  static const double xs = 8.0;

  /// 12px — compact spacing, between list item rows.
  static const double sm = 12.0;

  /// 16px — standard spacing, between form fields, card internal padding.
  static const double md = 16.0;

  /// 20px — page-edge horizontal padding, section padding.
  static const double lg = 20.0;

  /// 24px — comfortable spacing, between major sections, profile gaps.
  static const double xl = 24.0;

  /// 32px — large spacer, between content blocks, header-to-content.
  static const double xxl = 32.0;

  /// 48px — extra-large spacer, top of auth screens above logo.
  static const double xxxl = 48.0;

  // ============================================================
  // BORDER RADIUS SCALE
  // ============================================================

  /// 6px — micro radius: badge containers, small chips.
  static const double radiusXs = 6.0;

  /// 8px — small radius: thumbnail images, small cards.
  static const double radiusSm = 8.0;

  /// 12px — medium radius: input fields, buttons, standard cards.
  static const double radiusMd = 12.0;

  /// 14px — search bar, search result cards.
  static const double radiusMdPlus = 14.0;

  /// 16px — large cards, info containers in profile.
  static const double radiusLg = 16.0;

  /// 18px — hero banner, large feature cards.
  static const double radiusXl = 18.0;

  /// 20px — pill-shaped containers, nav item highlight.
  static const double radiusXxl = 20.0;

  /// 100px — full pill / circle — avatar, dot indicators, circular buttons.
  static const double radiusFull = 100.0;

  // ============================================================
  // BORDER RADIUS SHORTCUTS
  // Pre-built BorderRadius objects for common use cases.
  // ============================================================

  /// Radius for small badges and overline chips.
  static BorderRadius get badgeRadius =>
      BorderRadius.circular(radiusXs);

  /// Radius for standard buttons and input fields.
  static BorderRadius get buttonRadius =>
      BorderRadius.circular(radiusMd);

  /// Radius for search bar and search result items.
  static BorderRadius get searchRadius =>
      BorderRadius.circular(radiusMdPlus);

  /// Radius for standard content cards (profile info, trending items).
  static BorderRadius get cardRadius =>
      BorderRadius.circular(radiusLg);

  /// Radius for hero banner and large feature cards.
  static BorderRadius get bannerRadius =>
      BorderRadius.circular(radiusXl);

  /// Full pill — nav item highlight, dot indicators.
  static BorderRadius get pillRadius =>
      BorderRadius.circular(radiusFull);

  // ============================================================
  // PAGE LAYOUT
  // Standard padding for full-screen content areas.
  // ============================================================

  /// Horizontal margin applied to all page-level content.
  /// 20px left + 20px right — consistent with current app design.
  static const double pageHorizontal = 20.0;

  /// Vertical padding at the top of page content (inside SafeArea).
  static const double pageTopPadding = 20.0;

  /// Standard full-page padding (horizontal + vertical).
  /// Used for auth screens with EdgeInsets.all().
  static const double pagePadding = 24.0;

  /// Full EdgeInsets for page-level content (inside SafeArea).
  static const EdgeInsets pagePad = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageTopPadding,
  );

  /// EdgeInsets for auth screen bodies — slightly more vertical padding.
  static const EdgeInsets authPad = EdgeInsets.all(pagePadding);

  /// Horizontal-only insets for content rows.
  static const EdgeInsets hPad = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );

  // ============================================================
  // COMPONENT SIZES
  // Fixed dimensions for recurring UI components.
  // ============================================================

  /// Standard height for primary action buttons (Login, Register, Logout).
  static const double buttonHeight = 50.0;

  /// Home screen hero banner height.
  static const double heroBannerHeight = 210.0;

  /// SliverAppBar expandedHeight on Movie Detail screen.
  static const double detailAppBarHeight = 280.0;

  /// Bottom navigation bar height (excluding SafeArea insets).
  static const double bottomNavHeight = 60.0;

  /// App logo icon size on auth screens.
  static const double authLogoSize = 72.0;

  /// Header logo size in the Home tab app bar area.
  static const double headerLogoSize = 32.0;

  // ── Avatar ──────────────────────────────────────────────────

  /// Large avatar circle — Profile tab.
  static const double avatarLg = 84.0;

  /// Small avatar / initial circle — future use in list tiles.
  static const double avatarSm = 40.0;

  // ── Poster thumbnails ────────────────────────────────────────

  /// Trending list poster: width × height.
  static const double trendingPosterW = 46.0;
  static const double trendingPosterH = 64.0;

  /// Search result poster: width × height.
  static const double searchPosterW = 52.0;
  static const double searchPosterH = 74.0;

  /// Movie detail poster thumbnail: width × height.
  static const double detailPosterW = 96.0;
  static const double detailPosterH = 138.0;

  /// Cast section circular avatar diameter.
  static const double castAvatarSize = 48.0;

  /// Similar / Recommendation poster card: width × height.
  static const double similarPosterW = 90.0;
  static const double similarPosterH = 128.0;

  // ── Icon sizes ────────────────────────────────────────────────

  /// Standard icon inside buttons and nav.
  static const double iconMd = 20.0;

  /// Larger decorative icon (empty state illustrations).
  static const double iconXl = 56.0;

  /// Extra-large empty state icon.
  static const double iconXxl = 64.0;
}
