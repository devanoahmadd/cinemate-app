import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Assembles the complete [ThemeData] for Cinemate.
///
/// HOW IT WORKS:
///   [AppTheme.dark] is the single ThemeData instance passed to
///   [MaterialApp.theme]. It is composed from:
///     - [AppColors]      → ColorScheme, scaffold, widget fill colors
///     - [AppTypography]  → TextTheme mapping
///     - [AppSpacing]     → Radius values on button/input shapes
///
/// USAGE in main.dart:
///   MaterialApp.router(
///     theme: AppTheme.dark,
///     ...
///   )
///
/// RULES:
///   - NEVER construct ThemeData outside of this file
///   - NEVER override theme at widget level unless for one-off edge cases
///   - Global widget defaults belong here — if you're writing the same
///     style on multiple screens, it should be promoted to this file
///
/// EXTENSION PATTERN:
///   To add a new component theme (e.g., ChipTheme), add a private static
///   method `_chipTheme()` following the existing naming pattern, then
///   reference it inside [dark].
abstract class AppTheme {
  AppTheme._(); // prevents instantiation

  // ============================================================
  // PUBLIC ENTRY POINT
  // ============================================================

  /// The one and only ThemeData for Cinemate.
  /// Dark mode only — the app does not support light mode.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,

        // ── Color Scheme ──────────────────────────────────────
        colorScheme: _colorScheme,

        // ── Scaffold ──────────────────────────────────────────
        scaffoldBackgroundColor: AppColors.background,

        // ── System UI Overlay ─────────────────────────────────
        // Makes the status bar text white (icons visible on dark bg)
        appBarTheme: _appBarTheme,

        // ── Typography ────────────────────────────────────────
        textTheme: _textTheme,
        fontFamily: AppTypography.fontFamily,

        // ── Input fields ──────────────────────────────────────
        inputDecorationTheme: _inputDecorationTheme,

        // ── Buttons ───────────────────────────────────────────
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,

        // ── Bottom Navigation ─────────────────────────────────
        // Note: Cinemate uses a custom _NavItem widget, not the
        // built-in BottomNavigationBar, so this theme is a
        // safety-net for any future standard usage.
        bottomNavigationBarTheme: _bottomNavTheme,

        // ── Dialogs ───────────────────────────────────────────
        dialogTheme: _dialogTheme,

        // ── Dividers ──────────────────────────────────────────
        dividerTheme: _dividerTheme,

        // ── Cards ─────────────────────────────────────────────
        cardTheme: _cardTheme,

        // ── SnackBar ──────────────────────────────────────────
        snackBarTheme: _snackBarTheme,

        // ── Progress Indicator ────────────────────────────────
        progressIndicatorTheme: _progressIndicatorTheme,

        // ── Icons ─────────────────────────────────────────────
        iconTheme: _iconTheme,

        // ── Chips ─────────────────────────────────────────────
        chipTheme: _chipTheme,

        // ── ListTile ──────────────────────────────────────────
        listTileTheme: _listTileTheme,
      );

  // ============================================================
  // COLOR SCHEME
  // ============================================================

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Brand
    primary: AppColors.primary,
    onPrimary: AppColors.textPrimary,

    // Teal accent — verified status indicator (accent2)
    secondary: AppColors.accent2,
    onSecondary: AppColors.textPrimary,

    // Error states
    error: AppColors.error,
    onError: AppColors.textPrimary,

    // Backgrounds & surfaces
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,

    // Tertiary — card accent for decorative highlights
    tertiary: AppColors.cardAccent,
    onTertiary: AppColors.textPrimary,

    // Variant surfaces
    surfaceContainerHighest: AppColors.surfaceVariant,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
  );

  // ============================================================
  // APP BAR
  // ============================================================

  static final AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,  // no color shift when content scrolls under
    centerTitle: false,
    titleTextStyle: AppTypography.subtitle1,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    // Force white status bar icons on the dark background
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,   // Android
      statusBarBrightness: Brightness.dark,         // iOS
    ),
  );

  // ============================================================
  // TEXT THEME
  // Maps AppTypography styles to Material 3 TextTheme slots.
  //
  // Material 3 naming → Cinemate equivalent:
  //   headlineMedium (28px) → heading1 (28px, auth titles)
  //   headlineSmall  (24px) → heading2 (26px, page headers)
  //   titleLarge     (22px) → heading3 (20px, content titles)
  //   titleMedium    (16px) → subtitle1 (17px, section titles)
  //   titleSmall     (14px) → subtitle2 (14px, card titles)
  //   bodyLarge      (16px) → body1 (15px, synopsis)
  //   bodyMedium     (14px) → body2 (13px, descriptions)
  //   bodySmall      (12px) → caption (12px, metadata)
  //   labelLarge     (14px) → button (16px, button labels)
  //   labelSmall     (11px) → overline (10px, badge labels)
  // ============================================================

  static TextTheme get _textTheme => TextTheme(
    // Headings
    headlineMedium: AppTypography.heading1,
    headlineSmall: AppTypography.heading2,
    titleLarge: AppTypography.heading3,

    // Subtitles
    titleMedium: AppTypography.subtitle1,
    titleSmall: AppTypography.subtitle2,

    // Body
    bodyLarge: AppTypography.body1,
    bodyMedium: AppTypography.body2,
    bodySmall: AppTypography.caption,

    // Labels
    labelLarge: AppTypography.button,
    labelSmall: AppTypography.overline,
  );

  // ============================================================
  // INPUT DECORATION
  // Applies to ALL TextField widgets app-wide unless overridden.
  // ============================================================

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),

        // Label (floating) style
        labelStyle: const TextStyle(color: AppColors.textDisabled),

        // Hint text style
        hintStyle: const TextStyle(color: AppColors.textDisabled),

        // Prefix icon color
        prefixIconColor: AppColors.textDisabled,

        // Helper / error / counter text
        helperStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),

        // Content padding — matches current app's 14px vertical
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),

        // ── Border states ──────────────────────────────────────
        // Default border shape (used as base for all border states below)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),

        // Inactive / idle — subtle outline so field is still visible
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.divider,  // white 8% — barely-there border
            width: 1.0,
          ),
        ),

        // Active / focused — primary accent color, slightly thicker
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        // Error state — error color outline
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.0,
          ),
        ),

        // Focused + error — thicker error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),

        // Disabled state
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      );

  // ============================================================
  // ELEVATED BUTTON
  // Primary CTA — "Masuk", "Daftar"
  // ============================================================

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
      disabledForegroundColor: AppColors.textPrimary.withValues(alpha: 0.5),

      // Matches current app's 50px button height
      minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),

      // Typography
      textStyle: AppTypography.button,

      // Shape
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),

      // Remove default Material elevation — using BoxShadow in AppShadows
      elevation: 0,
      shadowColor: Colors.transparent,

      // Tap ripple color
      overlayColor: Colors.white.withValues(alpha: 0.1),

      // Internal padding
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    ),
  );

  // ============================================================
  // OUTLINED BUTTON
  // Secondary action — logout button (outlined style)
  // ============================================================

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1.0),
      minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
      textStyle: AppTypography.button.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  );

  // ============================================================
  // TEXT BUTTON
  // Tertiary / inline actions — "Lihat Semua", nav links
  // ============================================================

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTypography.link,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs4,
      ),
      overlayColor: AppColors.primary.withValues(alpha: 0.08),
    ),
  );

  // ============================================================
  // BOTTOM NAVIGATION BAR
  // Safety-net theme — Cinemate uses a custom nav widget.
  // ============================================================

  static const BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textDisabled,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  );

  // ============================================================
  // DIALOG
  // ============================================================

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceVariant,
    surfaceTintColor: Colors.transparent,  // disable M3 tint overlay
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      side: const BorderSide(color: AppColors.divider),
    ),
    titleTextStyle: AppTypography.subtitle1.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: AppTypography.body2.copyWith(
      color: AppColors.textTertiary,
    ),
  );

  // ============================================================
  // DIVIDER
  // ============================================================

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,    // zero extra spacing — callers add SizedBox manually
  );

  // ============================================================
  // CARD
  // ============================================================

  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      side: const BorderSide(color: AppColors.divider),
    ),
  );

  // ============================================================
  // SNACK BAR
  // ============================================================

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.surfaceVariant,
    contentTextStyle: AppTypography.body2.copyWith(
      color: AppColors.textPrimary,
    ),
    actionTextColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    elevation: 0,
  );

  // ============================================================
  // PROGRESS INDICATOR
  // ============================================================

  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.divider,
  );

  // ============================================================
  // ICON
  // ============================================================

  static const IconThemeData _iconTheme = IconThemeData(
    color: AppColors.textSecondary,
    size: AppSpacing.iconMd,
  );

  // ============================================================
  // CHIP
  // Genre quick-filter chips in Search placeholder
  // ============================================================

  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: Colors.white.withValues(alpha: 0.06),
    labelStyle: AppTypography.body2.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    side: const BorderSide(color: AppColors.divider),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs4,
    ),
    elevation: 0,
  );

  // ============================================================
  // LIST TILE
  // ============================================================

  static const ListTileThemeData _listTileTheme = ListTileThemeData(
    tileColor: Colors.transparent,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs4,
    ),
    iconColor: AppColors.textTertiary,
    textColor: AppColors.textPrimary,
  );
}
