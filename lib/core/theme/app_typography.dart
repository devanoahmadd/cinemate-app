import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography scale for Cinemate.
///
/// FONT: Plus Jakarta Sans (loaded automatically via google_fonts package).
/// No local font asset files needed — downloaded on first run and cached.
///
/// PREREQUISITE — google_fonts must be in pubspec.yaml:
///   dependencies:
///     google_fonts: ^6.2.1
///   Then run: flutter pub get
///
/// OFFLINE SUPPORT (optional):
///   To bundle fonts for offline/no-internet environments, download from
///   https://fonts.google.com/specimen/Plus+Jakarta+Sans and add to assets.
///   Then call: GoogleFonts.config.allowRuntimeFetching = false; in main()
///
/// NAMING CONVENTION:
///   heading1  > heading2  > heading3
///   subtitle1 > subtitle2
///   body1     > body2
///   caption   > overline
///   button    > link      > navLabel
///   greeting  > greetingSub   (home screen special)
///
/// USAGE:
///   Text('Title', style: AppTypography.heading1)
///   Text('Body',  style: AppTypography.body1)
///   // One-off variant — keep it local, don't pollute this file:
///   Text('Hint',  style: AppTypography.caption.copyWith(color: AppColors.primary))
///
/// RULES:
///   - NEVER create a TextStyle inline in widget files
///   - If you need a variant, use .copyWith() from a base style here
///   - All styles default to textPrimary or textSecondary — override via .copyWith()
///   - Styles are getters (not const) because GoogleFonts returns runtime objects.
///     The google_fonts package caches results internally so repeated calls are cheap.
abstract class AppTypography {
  AppTypography._(); // prevents instantiation

  // ============================================================
  // FONT FAMILY REFERENCE
  // Resolved at runtime from the google_fonts package.
  // AppTheme reads this to set ThemeData.fontFamily as the global fallback,
  // ensuring any Text widget without an explicit style also gets Plus Jakarta Sans.
  // ============================================================

  /// The resolved family name — e.g. "PlusJakartaSans".
  /// Used by AppTheme.dark via: fontFamily: AppTypography.fontFamily
  static String get fontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  // ============================================================
  // HEADINGS
  // High-weight, large text — draws the eye first.
  // Used for: screen titles, hero banners, movie detail title.
  // ============================================================

  /// Auth screen titles — "Selamat Datang", "Buat Akun".
  /// 28px / ExtraBold (w800) / tight tracking for display weight
  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  /// Page-level headers — "Search", "Profile", "Trending".
  /// 26px / ExtraBold (w800) / tight tracking
  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      );

  /// Content headings — movie detail title, category label.
  /// 20px / Bold (w700)
  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  // ============================================================
  // SUBTITLES
  // Medium-weight — secondary hierarchy within a section.
  // Used for: section titles, card titles, list item labels.
  // ============================================================

  /// In-screen section titles — "Jelajahi", "Trending Hari Ini".
  /// 17px / Bold (w700) / slight tight tracking
  static TextStyle get subtitle1 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      );

  /// Card-level titles — movie title inside list / search result cards.
  /// 14px / SemiBold (w600)
  static TextStyle get subtitle2 => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ============================================================
  // BODY
  // Regular-weight — long-form readable text.
  // Used for: synopsis, descriptions, dialog content, profile values.
  // ============================================================

  /// Primary body — synopsis, descriptions, profile info values.
  /// 15px / Regular (w400) / relaxed line height for comfortable reading.
  static TextStyle get body1 => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  /// Secondary body — shorter descriptions, search result overview snippets.
  /// 13px / Regular (w400)
  static TextStyle get body2 => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ============================================================
  // SMALL TEXT
  // Low emphasis — supplementary metadata, counters, labels.
  // ============================================================

  /// Captions — rating numbers, release year, result count ("12 hasil ditemukan").
  /// 12px / Medium (w500)
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  /// Overline — badge labels, ALL-CAPS chip text, "HOT", "NOW PLAYING".
  /// 10px / ExtraBold (w800) / wide letter spacing — maintains legibility at tiny size.
  static TextStyle get overline => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
        height: 1.4,
      );

  // ============================================================
  // INTERACTIVE
  // Action-oriented text — tap targets, navigation, links.
  // ============================================================

  /// Primary button label — "Masuk", "Daftar", "Keluar".
  /// 16px / SemiBold (w600) / minimal letter spacing
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
        height: 1.0,
      );

  /// Hyperlinks & "see all" — "Lihat Semua", "Lupa Password?", "Daftar".
  /// 13px / SemiBold (w600) / primary accent color by default.
  static TextStyle get link => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.4,
      );

  /// Bottom navigation bar label — "Home", "Search", "Profile".
  /// 10px / SemiBold for active state.
  /// For inactive state: navLabel.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w400)
  static TextStyle get navLabel => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.primary, // active — override for inactive via .copyWith()
        letterSpacing: 0.1,
        height: 1.2,
      );

  // ============================================================
  // GREETING / SPECIAL PURPOSE
  // One-off styles for specific recurring components.
  // ============================================================

  /// Home tab greeting — "Halo, username!".
  /// 20px / Bold (w700) / subtle tracking
  static TextStyle get greeting => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.3,
      );

  /// Home tab sub-greeting — "Mau nonton apa hari ini?".
  /// 13px / Regular (w400) / tertiary color for intentionally reduced emphasis.
  static TextStyle get greetingSub => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );
}
