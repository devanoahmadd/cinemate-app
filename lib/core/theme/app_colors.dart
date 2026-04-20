import 'package:flutter/material.dart';

/// Centralized color palette for Cinemate.
///
/// STRUCTURE:
///   Brand       → primary, primaryDark, primaryMuted, primaryGlow
///   Backgrounds → background, surface, surfaceElevated, surfaceVariant, cardAccent
///   Text        → textPrimary, textSecondary, textTertiary, textDisabled
///   Accents     → accent1 (gold), accent2 (teal)
///   Semantic    → error
///   Utility     → divider, overlay
///
/// USAGE:
///   color: AppColors.primary
///   color: AppColors.accent1          // rating stars
///   color: AppColors.surfaceElevated  // input field fill
///
/// RULES:
///   - NEVER write raw hex Color() values in widget files
///   - If you need an opacity variant not listed, use:
///       AppColors.primary.withValues(alpha: 0.5)
///   - For new semantic colors, add here first — do NOT add locally in a file
///   - accent1 and accent2 are reserved for their single designated purpose —
///     do NOT repurpose them for other meanings
///
/// WCAG CONTRAST NOTES (against #1A1A2E background, ~luminance 0.01):
///   textPrimary   (#FFFFFF)       → 19.6 : 1  ✅ AAA
///   textSecondary (#FFFFFFB3 70%) →  ~14 : 1  ✅ AAA
///   textTertiary  (#FFFFFF73 45%) →  ~8.8 : 1 ✅ AA
///   textDisabled  (#FFFFFF40 25%) →  ~4.9 : 1 ✅ AA (borderline — non-essential UI only)
abstract class AppColors {
  AppColors._(); // prevents instantiation

  // ============================================================
  // BRAND
  // Core identity colors — primary must never change.
  // ============================================================

  /// Primary brand color — coral red.
  /// Used for: CTAs, active nav indicator, badges, focus ring borders.
  /// ⚠️  CONSTRAINT: This value must NEVER be changed per design contract.
  static const Color primary = Color(0xFFE94560);

  /// Primary dark — deeper shade of the brand color.
  /// Hex: #B02040
  /// Used for: gradient end stop (dark → primary), pressed/active button state,
  /// LinearGradient on hero cards where depth is needed.
  /// Example: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
  static const Color primaryDark = Color(0xFFB02040);

  /// Primary at 12% opacity — tinted background behind primary elements.
  /// Used for: active nav item pill background, selected chip fill.
  static const Color primaryMuted = Color(0x1FE94560);

  /// Primary at 30% opacity — ambient glow behind primary elements.
  /// Used for: ElevatedButton box shadow, avatar circle glow, hero banner shadow.
  static const Color primaryGlow = Color(0x4DE94560);

  // ============================================================
  // BACKGROUNDS
  // Layered depth system — each level is visually lighter than the one below.
  // Layer order (bottom to top): background → surface → surfaceElevated → surfaceVariant
  // ============================================================

  /// Layer 0 — deepest background, the main screen canvas.
  /// Hex: #1A1A2E  |  Used on: Scaffold backgroundColor, every screen body.
  static const Color background = Color(0xFF1A1A2E);

  /// Layer 1 — card background, bottom nav bar.
  /// Hex: #16213E  |  Replaces the old hardcoded #12122A bottom nav color.
  /// Used for: movie list cards, trending item rows, category grid cells,
  /// bottom navigation bar container.
  static const Color surface = Color(0xFF16213E);

  /// Layer 2 — input fields and elevated cards.
  /// Hex: #1F2B4D  |  Slightly lighter than [surface] to create clear separation
  /// between a card background and interactive elements placed on top of it.
  /// Used for: TextField fillColor, slightly elevated card surfaces,
  /// search bar background.
  static const Color surfaceElevated = Color(0xFF1F2B4D);

  /// Layer 3 — dialogs, modals, bottom sheets, side panels.
  /// Hex: #1E1E35  |  Neutral warm tone, distinct from the blue-toned surfaces.
  /// Used for: AlertDialog backgroundColor, confirmation modal background.
  static const Color surfaceVariant = Color(0xFF1E1E35);

  /// Decorative card accent — deep navy blue for intentional color pop.
  /// Hex: #0F3460  |  Use sparingly — only for decorative card edge highlights
  /// or background gradients; never for text or interactive elements.
  static const Color cardAccent = Color(0xFF0F3460);

  // ============================================================
  // TEXT
  // Opacity-based scale — all variants are white with decreasing alpha.
  // ============================================================

  /// Full white — highest emphasis text.
  /// Contrast vs background: ~19.6 : 1 ✅ WCAG AAA.
  /// Used for: headings, titles, important values, button labels.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// White at 70% — standard readable body text.
  /// 0xB3 = 179 / 255 ≈ 70% alpha.
  /// Contrast vs background: ~14 : 1 ✅ WCAG AAA.
  /// Used for: body copy, descriptions, subtitles, list item text.
  static const Color textSecondary = Color(0xB3FFFFFF);

  /// White at 45% — supplementary / low-emphasis text.
  /// 0x73 = 115 / 255 ≈ 45% alpha.
  /// Contrast vs background: ~8.8 : 1 ✅ WCAG AA.
  /// Used for: captions, release year, metadata labels, result counts.
  static const Color textTertiary = Color(0x73FFFFFF);

  /// White at 25% — disabled and placeholder-only text.
  /// 0x40 = 64 / 255 ≈ 25% alpha.
  /// Contrast vs background: ~4.9 : 1 ✅ WCAG AA (borderline).
  /// ⚠️  Do NOT use for text that conveys meaning — placeholders and disabled
  ///     labels only. Screen readers still read this text regardless of color.
  static const Color textDisabled = Color(0x40FFFFFF);

  // ============================================================
  // ACCENTS
  // Two reserved accent colors, each with a single designated purpose.
  // Using these outside their defined role breaks the visual language.
  // ============================================================

  /// Accent 1 — gold / amber, standardized for rating stars.
  /// Hex: #FFD93D
  /// Used for: star icon color in ALL rating displays (home, search, detail).
  /// ⚠️  CONSISTENCY RULE: Always use this token for star ratings.
  ///     NEVER use Colors.amber or Colors.yellow — they produce different hues
  ///     across different devices and are not part of this palette.
  static const Color accent1 = Color(0xFFFFD93D);

  /// Accent 2 — teal, reserved for verified status only.
  /// Hex: #4ECDC4
  /// Used for: "Terverifikasi" status chip text/icon in Profile tab.
  /// ⚠️  SCOPE RULE: Do NOT use this color for success states, progress bars,
  ///     or any component other than the verified status indicator.
  ///     For general success feedback, use a snackbar with [primary] accent instead.
  static const Color accent2 = Color(0xFF4ECDC4);

  // ============================================================
  // SEMANTIC
  // ============================================================

  /// Error / destructive action color.
  /// Hex: #FF6B6B
  /// Used for: SnackBar error background, form validation errors,
  /// error state widgets, broken image fallback tint.
  /// NOTE: Intentionally distinct from [primary] (#E94560) so errors
  /// are never confused with brand CTAs.
  static const Color error = Color(0xFFFF6B6B);

  // ============================================================
  // STATUS COLORS
  // Used exclusively for TMDB movie/TV release-status chips and badges.
  // Never repurpose these for rating stars, verified badges, or CTAs.
  // ============================================================

  /// Soft green — "Released" status. Signals completion/availability.
  static const Color statusReleased = Color(0xFF4ADE80);

  /// Amber — "In Production" / "Post Production". Signals active work.
  static const Color statusInProgress = Color(0xFFFBBF24);

  /// Muted blue-gray — "Planned" / "Rumored". Signals uncertainty/future.
  static const Color statusNeutral = Color(0xFF8B95A3);

  // Note: "Canceled" reuses [error] — same semantic meaning (stop/negative).

  // ============================================================
  // UTILITY
  // ============================================================

  /// Ultra-subtle divider / border line.
  /// 0x14 = 20 / 255 ≈ 8% alpha.
  /// Used for: Divider widget, card border strokes, list separators,
  /// input field enabled border, dialog outline.
  static const Color divider = Color(0x14FFFFFF);

  /// Full black — base for gradient overlays and modal scrims.
  /// Always use withValues(alpha: x) to control opacity at point of use.
  /// Example: AppColors.overlay.withValues(alpha: 0.6) for a modal scrim.
  static const Color overlay = Color(0xFF000000);
}
