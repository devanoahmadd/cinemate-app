import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized elevation & shadow system for Cinemate.
///
/// DESIGN PRINCIPLE:
///   On dark backgrounds, standard Material shadows (black-based) are nearly
///   invisible. Cinemate uses a two-strategy shadow system:
///     1. Tinted shadows (using [AppColors.primary] or card color) for
///        elements that should "glow" or pop (hero banner, avatar, CTA button).
///     2. Neutral dark shadows (black at opacity) for structural elevation
///        (bottom nav, dialogs, cards).
///
/// ALL properties return `List<BoxShadow>` for use in BoxDecoration.boxShadow.
///
/// USAGE:
///   BoxDecoration(
///     boxShadow: AppShadows.card,
///   )
///   BoxDecoration(
///     boxShadow: AppShadows.primaryGlow,
///   )
///
/// RULES:
///   - NEVER define BoxShadow inline in widget files
///   - Prefer pre-built named shadows — add new ones here if needed
///   - Use [primaryGlow] only for elements that directly represent
///     the primary action or brand (hero banner, CTA button, avatar)
abstract class AppShadows {
  AppShadows._(); // prevents instantiation

  // ============================================================
  // NEUTRAL SHADOWS
  // For structural elevation — does not draw attention by itself.
  // ============================================================

  /// Hairline shadow — subtle depth under cards and list items.
  /// Elevation level: 1 (barely visible, context separator only).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x29000000), // black at 16%
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium shadow — modal sheets, expanded cards, info containers.
  /// Elevation level: 2 (visible on surface, clear layer separation).
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x40000000), // black at 25%
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1A000000), // black at 10% — soft outer halo
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  /// Strong shadow — bottom navigation bar (above screen content).
  /// Uses an upward offset to cast shadow toward the screen content below.
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x66000000), // black at 40%
      blurRadius: 20,
      offset: Offset(0, -4),  // upward shadow
    ),
  ];

  /// Dialog / modal scrim shadow — deepest neutral elevation.
  /// Elevation level: 4 (clear floating surface).
  static const List<BoxShadow> dialog = [
    BoxShadow(
      color: Color(0x80000000), // black at 50%
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  // ============================================================
  // TINTED / GLOW SHADOWS
  // For brand-colored elements that should feel alive and prominent.
  // ============================================================

  /// Primary glow — hero banner, feature card.
  /// Creates the signature red ambient glow beneath the banner.
  static const List<BoxShadow> heroBanner = [
    BoxShadow(
      color: Color(0x38E94560), // primary at 22%
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// CTA button glow — ElevatedButton with primary color.
  /// Adds depth below the button without the shadow being distracting.
  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: Color(0x4DE94560), // primary at 30%
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x1AE94560), // primary at 10% — soft outer ring
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Avatar glow — Profile tab avatar circle.
  /// Soft primary halo reinforces brand identity on the profile page.
  static const List<BoxShadow> avatar = [
    BoxShadow(
      color: Color(0x59E94560), // primary at 35%
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// Play button glow — circular play icon on hero banner.
  static const List<BoxShadow> playButton = [
    BoxShadow(
      color: Color(0x66E94560), // primary at 40%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Accent2 glow — for the verified status chip (teal, AppColors.accent2).
  static const List<BoxShadow> successGlow = [
    BoxShadow(
      color: Color(0x334ECDC4), // accent2 (#4ECDC4) at 20%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ============================================================
  // GRADIENT OVERLAYS
  // Not BoxShadow, but gradient configs used alongside shadows.
  // Provided here for co-location with shadow logic.
  // ============================================================

  /// Standard hero banner bottom gradient — darkens the lower half.
  /// Apply as a DecoratedBox over the image inside a Stack.
  static const LinearGradient heroBannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000), // transparent top
      Color(0x40000000), // 25% mid
      Color(0xE0000000), // 88% bottom — ensures text legibility
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Movie detail app bar gradient — fades backdrop into the background color.
  /// Apply as a Container over the CachedNetworkImage in SliverAppBar.
  static const LinearGradient detailAppBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),    // transparent
      Color(0xCC1A1A2E),    // background at 80%
      Color(0xFF1A1A2E),    // full background color
    ],
  );
}
