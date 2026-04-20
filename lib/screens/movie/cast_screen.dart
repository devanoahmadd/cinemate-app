import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../data/models/cast_model.dart';

class CastScreen extends StatelessWidget {
  final String movieTitle;
  final List<CastModel> cast;

  const CastScreen({
    super.key,
    required this.movieTitle,
    required this.cast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
              color: AppColors.surfaceElevated,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Main Cast', style: AppTypography.subtitle1),
            Text(
              movieTitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.65,
        ),
        itemCount: cast.length,
        itemBuilder: (_, i) => _CastCell(member: cast[i]),
      ),
    );
  }
}

// ── Cast Cell ────────────────────────────────────────────────────────────────

class _CastCell extends StatelessWidget {
  final CastModel member;

  const _CastCell({required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        ClipOval(
          child: CachedNetworkImage(
            imageUrl: member.fullProfileUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            placeholder: (_, _) => _placeholder(),
            errorWidget: (_, _, _) => _placeholder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Name
        Text(
          member.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        // Character
        Text(
          member.character,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        color: AppColors.surfaceElevated,
        alignment: Alignment.center,
        child: Text(
          member.initials,
          style: AppTypography.subtitle2.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
}
