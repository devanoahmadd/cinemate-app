// Barrel export for the Cinemate Design System.
//
// USAGE — import a single line anywhere in the project:
//   import 'package:cinemate/core/theme/theme.dart';
//
// Then access any token directly:
//   AppColors.primary
//   AppTypography.heading1
//   AppSpacing.md
//   AppShadows.heroBanner
//   AppTheme.dark
//
// NEVER import individual theme files (app_colors.dart, etc.) directly
// in widget files — always go through this barrel so that reorganisation
// of the /theme folder only requires updating this one file.
export 'app_colors.dart';
export 'app_typography.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
