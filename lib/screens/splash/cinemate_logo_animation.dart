import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated Cinemate logo.
///
/// Draw order (back → front):
///   orbit ring → arc C → arms → center dot
///
/// Timeline (total 2400 ms):
///   dot       0.00–0.18  elasticOut
///   arm right 0.18–0.38  easeOutCubic
///   arm left  0.26–0.44  easeOutCubic
///   ring      0.40–0.62  easeInOutCubic
///   arc C     0.58–1.00  easeInOutCubic
class CinemateLogoAnimation extends StatefulWidget {
  final double size;
  const CinemateLogoAnimation({super.key, this.size = 160});

  @override
  State<CinemateLogoAnimation> createState() =>
      _CinemateLogoAnimationState();
}

class _CinemateLogoAnimationState extends State<CinemateLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _dot;
  late final Animation<double> _armR;
  late final Animation<double> _armL;
  late final Animation<double> _ring;
  late final Animation<double> _arcC;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _dot = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.18, curve: Curves.elasticOut),
    );
    _armR = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.38, curve: Curves.easeOutCubic),
    );
    _armL = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.26, 0.44, curve: Curves.easeOutCubic),
    );
    _ring = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.62, curve: Curves.easeInOutCubic),
    );
    _arcC = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.58, 1.00, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CinemateLogoPainter(
          dot:  _dot.value,
          armR: _armR.value,
          armL: _armL.value,
          ring: _ring.value,
          arcC: _arcC.value,
        ),
      ),
    );
  }
}

class _CinemateLogoPainter extends CustomPainter {
  final double dot, armR, armL, ring, arcC;

  const _CinemateLogoPainter({
    required this.dot,
    required this.armR,
    required this.armL,
    required this.ring,
    required this.arcC,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final s = size.width / 160.0; // uniform scale factor

    // ── 1. Orbit ring ─────────────────────────────────────────────
    if (ring > 0) {
      final t = ring.clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        40.0 * s * t,
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: 0.18 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * s,
      );
    }

    // ── 2. Arc C ──────────────────────────────────────────────────
    // Opens to the right: starts at 40°, sweeps 280° clockwise.
    if (arcC > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 55.0 * s),
        40 * pi / 180,
        (280 * pi / 180) * arcC,
        false,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13 * s
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 3. Arms (reel spokes) ──────────────────────────────────────
    final armLen = 26.0 * s;
    final tipR   = 4.8  * s;

    // Right arm → slides right, primary at 70%
    if (armR > 0) {
      final tip = Offset(center.dx + armLen * armR, center.dy);
      canvas.drawLine(
        center, tip,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * s
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        tip, tipR * armR,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill,
      );
    }

    // Left arm → slides left, primary at 35% (shadow / depth feel)
    if (armL > 0) {
      final tip = Offset(center.dx - armLen * armL, center.dy);
      canvas.drawLine(
        center, tip,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * s
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        tip, tipR * armL,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.50)
          ..style = PaintingStyle.fill,
      );
    }

    // ── 4. Center dot (top layer) ──────────────────────────────────
    // elasticOut lets dot value exceed 1.0 — that is the intentional bounce.
    if (dot > 0) {
      final r = max(0.0, 9.0 * s * dot);
      canvas.drawCircle(
        center, r,
        Paint()..color = AppColors.primary..style = PaintingStyle.fill,
      );
      // Inner dark hole gives the hub-of-reel feel
      if (dot > 0.4) {
        canvas.drawCircle(
          center, r * 0.42,
          Paint()..color = AppColors.background..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CinemateLogoPainter old) =>
      old.dot  != dot  ||
      old.armR != armR ||
      old.armL != armL ||
      old.ring != ring ||
      old.arcC != arcC;
}
