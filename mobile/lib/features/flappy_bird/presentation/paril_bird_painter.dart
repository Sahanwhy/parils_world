import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../domain/models/game_models.dart';

/// CustomPainter rendering the entire Paril Bird game scene.
class ParilBirdPainter extends CustomPainter {
  ParilBirdPainter({
    required this.birdY,
    required this.birdVelocity,
    required this.birdX,
    required this.birdImage,
    this.crashedImage,
    this.bgImage,
    required this.obstacles,
    required this.iceCreams,
    required this.particles,
    required this.floatingTexts,
    required this.groundOffset,
    required this.groundHeight,
    required this.elapsedTime,
    required this.isPlaying,
    required this.isGameOver,
  });

  final double birdY;
  final double birdVelocity;
  final double birdX;
  final ui.Image? birdImage;
  final ui.Image? crashedImage;
  final ui.Image? bgImage;
  final List<VegetableObstacle> obstacles;
  final List<IceCreamBonus> iceCreams;
  final List<GameParticle> particles;
  final List<FloatingScoreText> floatingTexts;
  final double groundOffset;
  final double groundHeight;
  final double elapsedTime;
  final bool isPlaying;
  final bool isGameOver;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkyBackground(canvas, size);
    _drawDistantHills(canvas, size);
    _drawClouds(canvas, size);
    _drawVegetableObstacles(canvas, size);
    _drawIceCreams(canvas);
    _drawParticles(canvas);
    _drawParilBird(canvas);
    _drawFloatingTexts(canvas);
    _drawGardenGround(canvas, size);
  }

  // ── 1. Sky & Celestial Atmosphere ─────────────────────────────────────────
  void _drawSkyBackground(Canvas canvas, Size size) {
    final dest = Rect.fromLTWH(0, 0, size.width, size.height);

    if (bgImage != null) {
      // Draw the custom background image, centered (cover-fit).
      final imgW = bgImage!.width.toDouble();
      final imgH = bgImage!.height.toDouble();
      final imgAspect = imgW / imgH;
      final screenAspect = size.width / size.height;

      double srcX = 0, srcY = 0, srcW = imgW, srcH = imgH;
      if (imgAspect > screenAspect) {
        // Image is wider — crop sides to center
        srcW = imgH * screenAspect;
        srcX = (imgW - srcW) / 2;
      } else {
        // Image is taller — crop top/bottom to center
        srcH = imgW / screenAspect;
        srcY = (imgH - srcH) / 2;
      }
      final src = Rect.fromLTWH(srcX, srcY, srcW, srcH);
      canvas.drawImageRect(
        bgImage!,
        src,
        dest,
        Paint()..filterQuality = FilterQuality.medium,
      );

      // Subtle dark vignette so game elements stay readable
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
        ).createShader(dest);
      canvas.drawRect(dest, vignettePaint);
      return;
    }

    // Fallback sky gradient when image hasn't loaded yet
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D0B1A), // Deep twilight navy
          Color(0xFF1B1633), // Violet night
          Color(0xFF2E1B3E), // Dusky rose violet
          Color(0xFF4A2542), // Warm garden horizon
        ],
        stops: [0.0, 0.45, 0.75, 1.0],
      ).createShader(dest);
    canvas.drawRect(dest, skyPaint);

    // Subtle twinkling stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 28; i++) {
      final sx = ((i * 37 + 19) % size.width);
      final sy = ((i * 59 + 23) % (size.height * 0.55));
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(elapsedTime * 3.0 + i));
      starPaint.color = Colors.white.withValues(alpha: (0.35 * twinkle).clamp(0.0, 1.0));
      final starSize = (i % 3 == 0) ? 2.2 : 1.4;
      canvas.drawCircle(Offset(sx, sy), starSize, starPaint);
    }
  }

  // ── 2. Distant Garden Hills ───────────────────────────────────────────────
  void _drawDistantHills(Canvas canvas, Size size) {
    final hillY = size.height - groundHeight - 40;
    final hillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241630), Color(0xFF160E20)],
      ).createShader(Rect.fromLTWH(0, hillY, size.width, 100));

    final path = Path()..moveTo(0, size.height - groundHeight);
    for (double x = 0; x <= size.width; x += 30) {
      final y = hillY + math.sin((x + groundOffset * 0.2) * 0.012) * 18;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height - groundHeight);
    path.close();
    canvas.drawPath(path, hillPaint);
  }

  // ── 3. Drifting Clouds ────────────────────────────────────────────────────
  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = const Color(0x28FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < 3; i++) {
      final cx = ((i * 180 + groundOffset * 0.15) % (size.width + 160)) - 80;
      final cy = 60.0 + i * 45;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 110, height: 32),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 25, cy - 8), width: 70, height: 38),
        cloudPaint,
      );
    }
  }

  // ── 4. Vegetable Obstacle Walls ───────────────────────────────────────────
  void _drawVegetableObstacles(Canvas canvas, Size size) {
    for (final obs in obstacles) {
      if (obs.x + obs.width < -10 || obs.x > size.width + 10) continue;

      final topRect = obs.topRect;
      final bottomRect = obs.bottomRect(size.height, groundHeight);

      switch (obs.type) {
        case VegetableType.carrot:
          _drawCarrotWall(canvas, topRect, isTop: true);
          _drawCarrotWall(canvas, bottomRect, isTop: false);
          break;
        case VegetableType.broccoli:
          _drawBroccoliWall(canvas, topRect, isTop: true);
          _drawBroccoliWall(canvas, bottomRect, isTop: false);
          break;
        case VegetableType.cucumber:
          _drawCucumberWall(canvas, topRect, isTop: true);
          _drawCucumberWall(canvas, bottomRect, isTop: false);
          break;
        case VegetableType.eggplant:
          _drawEggplantWall(canvas, topRect, isTop: true);
          _drawEggplantWall(canvas, bottomRect, isTop: false);
          break;
      }
    }
  }

  /// Carrot Wall: vibrant orange root with natural creases and leafy green tops.
  void _drawCarrotWall(Canvas canvas, Rect rect, {required bool isTop}) {
    if (rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(12),
    );

    // Rich carrot gradient (orange to deep tangerine)
    final carrotShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFF9233),
        Color(0xFFFF6F00),
        Color(0xFFE65100),
        Color(0xFFBF360C),
      ],
      stops: const [0.0, 0.28, 0.72, 1.0],
    ).createShader(rect);

    final fillPaint = Paint()..shader = carrotShader;
    canvas.drawRRect(rrect, fillPaint);

    // Outline
    final strokePaint = Paint()
      ..color = const Color(0xFF5D1D05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, strokePaint);

    // Natural carrot ridges/grooves
    final ridgePaint = Paint()
      ..color = const Color(0x66BF360C)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final startY = isTop ? 10.0 : rect.top + 10;
    final endY = isTop ? rect.bottom - 10 : rect.bottom - 10;
    for (double y = startY; y < endY; y += 22.0) {
      final indent = (y.toInt() % 3 == 0) ? 8.0 : 14.0;
      canvas.drawLine(
        Offset(rect.left + 8, y),
        Offset(rect.right - indent, y),
        ridgePaint,
      );
    }

    // Leafy carrot greens at the tip/edge
    _drawCarrotGreens(canvas, rect, isTop: isTop);
  }

  void _drawCarrotGreens(Canvas canvas, Rect rect, {required bool isTop}) {
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7CB342), Color(0xFF33691E)],
      ).createShader(rect);

    final edgeY = isTop ? rect.bottom : rect.top;
    final dir = isTop ? 1.0 : -1.0;

    // Draw leafy fringe fronds
    final path = Path();
    final centerX = rect.center.dx;
    for (int i = -2; i <= 2; i++) {
      final lx = centerX + i * 12;
      path.moveTo(lx - 6, edgeY);
      path.quadraticBezierTo(
        lx + i * 4,
        edgeY + dir * 14,
        lx + 6,
        edgeY,
      );
    }
    canvas.drawPath(path, leafPaint);
  }

  /// Broccoli Wall: thick green stem crowned by massive fluffy broccoli florets.
  void _drawBroccoliWall(Canvas canvas, Rect rect, {required bool isTop}) {
    if (rect.height <= 0) return;

    // Stalk
    final stalkRect = Rect.fromLTWH(
      rect.left + 8,
      rect.top,
      rect.width - 16,
      rect.height,
    );
    final stalkPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF2E7D32)],
      ).createShader(stalkRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(stalkRect, const Radius.circular(8)),
      stalkPaint,
    );

    // Fluffy floret crown facing the gap
    final crownY = isTop ? rect.bottom - 10 : rect.top + 10;
    final crownPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
      ).createShader(Rect.fromCircle(center: Offset(rect.center.dx, crownY), radius: 30));

    // Bumpy florets
    final floretOffsets = [
      Offset(rect.left + 10, crownY),
      Offset(rect.left + 26, crownY - (isTop ? 6 : -6)),
      Offset(rect.center.dx, crownY),
      Offset(rect.right - 26, crownY - (isTop ? 6 : -6)),
      Offset(rect.right - 10, crownY),
    ];
    for (final pos in floretOffsets) {
      canvas.drawCircle(pos, 14, crownPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF0F3811)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(stalkRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  /// Cucumber Wall: fresh sliced cucumber look with pale center and seeds.
  void _drawCucumberWall(Canvas canvas, Rect rect, {required bool isTop}) {
    if (rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Cucumber outer dark green
    final skinPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF43A047), Color(0xFF1B5E20), Color(0xFF0D3310)],
      ).createShader(rect);
    canvas.drawRRect(rrect, skinPaint);

    // Juicy pale inner core
    final innerRect = Rect.fromLTWH(
      rect.left + 10,
      rect.top + 4,
      rect.width - 20,
      rect.height - 8,
    );
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      ).createShader(innerRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(10)),
      corePaint,
    );

    // Cucumber seeds down the center
    final seedPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;
    final startY = rect.top + 16;
    final endY = rect.bottom - 16;
    for (double y = startY; y < endY; y += 20) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rect.center.dx - 4, y), width: 4, height: 7),
        seedPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rect.center.dx + 4, y + 8), width: 4, height: 7),
        seedPaint,
      );
    }

    final outline = Paint()
      ..color = const Color(0xFF072109)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, outline);
  }

  /// Eggplant Wall: glossy regal purple with star-shaped green calyx at the stem.
  void _drawEggplantWall(Canvas canvas, Rect rect, {required bool isTop}) {
    if (rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Deep royal purple gradient with gloss
    final eggplantPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF7B1FA2),
          Color(0xFF4A148C),
          Color(0xFF310B5E),
          Color(0xFF1F053D),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, eggplantPaint);

    // Gloss reflection stripe
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + 12, rect.top + 10),
      Offset(rect.left + 12, rect.bottom - 10),
      glossPaint,
    );

    // Green Calyx crown at base or gap
    final calyxY = isTop ? rect.bottom : rect.top;
    final dir = isTop ? 1.0 : -1.0;
    final calyxPaint = Paint()..color = const Color(0xFF558B2F);

    final path = Path();
    path.moveTo(rect.left + 6, calyxY);
    path.lineTo(rect.left + 14, calyxY + dir * 14);
    path.lineTo(rect.center.dx, calyxY + dir * 18);
    path.lineTo(rect.right - 14, calyxY + dir * 14);
    path.lineTo(rect.right - 6, calyxY);
    path.close();
    canvas.drawPath(path, calyxPaint);

    final outline = Paint()
      ..color = const Color(0xFF140226)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(rrect, outline);
  }

  // ── 5. Ice Cream Collectibles ─────────────────────────────────────────────
  void _drawIceCreams(Canvas canvas) {
    for (final ice in iceCreams) {
      if (ice.collected) continue;

      final bob = math.sin(elapsedTime * 4.0 + ice.x) * 5.0;
      final pos = Offset(ice.x, ice.y + bob);

      // Glowing aura
      final glowPaint = Paint()
        ..color = const Color(0x66FF69B4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, 22, glowPaint);

      // Golden Waffle Cone
      final conePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFCC80), Color(0xFFD78C26)],
        ).createShader(Rect.fromLTWH(pos.dx - 12, pos.dy, 24, 24));

      final conePath = Path()
        ..moveTo(pos.dx - 10, pos.dy + 2)
        ..lineTo(pos.dx + 10, pos.dy + 2)
        ..lineTo(pos.dx, pos.dy + 22)
        ..close();
      canvas.drawPath(conePath, conePaint);

      // Waffle grid lines
      final waffleLine = Paint()
        ..color = const Color(0xFFB26B14)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(pos.dx - 6, pos.dy + 4), Offset(pos.dx + 2, pos.dy + 14), waffleLine);
      canvas.drawLine(Offset(pos.dx + 6, pos.dy + 4), Offset(pos.dx - 2, pos.dy + 14), waffleLine);

      // Ice Cream Scoop / Swirl
      List<Color> scoopColors;
      if (ice.flavorIndex == 0) {
        // Strawberry Swirl
        scoopColors = [const Color(0xFFFF80AB), const Color(0xFFFF4081)];
      } else if (ice.flavorIndex == 1) {
        // Mint Chocolate
        scoopColors = [const Color(0xFFB9F6CA), const Color(0xFF00E676)];
      } else {
        // Vanilla Lavender
        scoopColors = [const Color(0xFFE1BEE7), const Color(0xFFBA68C8)];
      }

      final scoopPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, scoopColors[0], scoopColors[1]],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(pos.dx - 3, pos.dy - 6), radius: 14));

      // Main scoop
      canvas.drawCircle(Offset(pos.dx, pos.dy - 3), 12, scoopPaint);
      // Top swirl
      canvas.drawCircle(Offset(pos.dx, pos.dy - 12), 7, scoopPaint);

      // Rainbow Sprinkles
      final sprinklePaint = Paint()
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      sprinklePaint.color = const Color(0xFFFFD54F);
      canvas.drawLine(Offset(pos.dx - 5, pos.dy - 5), Offset(pos.dx - 2, pos.dy - 3), sprinklePaint);

      sprinklePaint.color = const Color(0xFF40C4FF);
      canvas.drawLine(Offset(pos.dx + 3, pos.dy - 7), Offset(pos.dx + 5, pos.dy - 4), sprinklePaint);

      // Cherry on top!
      final cherryPaint = Paint()..color = const Color(0xFFD50000);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 18), 3.5, cherryPaint);

      // Sparkle stars around ice cream
      final starAngle = elapsedTime * 3.0;
      final sparklePos = Offset(
        pos.dx + math.cos(starAngle) * 17,
        pos.dy + math.sin(starAngle) * 17,
      );
      final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(sparklePos, 2.0, sparklePaint);
    }
  }

  // ── 6. Trail and Sparkle Particles ────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (p.isDead) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      if (p.isHeart) {
        _drawMiniHeart(canvas, Offset(p.x, p.y), p.size * p.life, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
      }
    }
  }

  void _drawMiniHeart(Canvas canvas, Offset center, double size, Paint paint) {
    if (size <= 0.5) return;
    final path = Path();
    final s = size;
    path.moveTo(center.dx, center.dy + s * 0.4);
    path.cubicTo(
      center.dx - s,
      center.dy - s * 0.4,
      center.dx - s * 0.6,
      center.dy - s,
      center.dx,
      center.dy - s * 0.4,
    );
    path.cubicTo(
      center.dx + s * 0.6,
      center.dy - s,
      center.dx + s,
      center.dy - s * 0.4,
      center.dx,
      center.dy + s * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  // ── 7. Paril Bird Hero ────────────────────────────────────────────────────
  void _drawParilBird(Canvas canvas) {
    canvas.save();
    canvas.translate(birdX, birdY);

    // Calculate rotation angle based on velocity
    // Tilts up when flapping (-20 deg), points down when falling (up to +45 deg)
    double angle = (birdVelocity * 0.0016).clamp(-0.45, 0.85);
    if (!isPlaying && !isGameOver) {
      // Gentle ready hover
      angle = math.sin(elapsedTime * 4.0) * 0.08;
    }
    canvas.rotate(angle);

    const targetWidth = 66.0;
    const targetHeight = 44.0;
    final birdRect = Rect.fromCenter(
      center: Offset.zero,
      width: targetWidth,
      height: targetHeight,
    );

    // Ambient glow under Paril
    final glowPaint = Paint()
      ..color = const Color(0x66E040FB)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2, 2), width: 68, height: 44),
      glowPaint,
    );

    if (isGameOver && crashedImage != null) {
      // Draw hilarious crashed face
      const crashSize = 52.0;
      final crashRect = Rect.fromCenter(
        center: Offset.zero,
        width: crashSize,
        height: crashSize,
      );
      final clipPath = Path()..addOval(crashRect);
      canvas.save();
      canvas.clipPath(clipPath);
      final src = Rect.fromLTWH(
        0,
        0,
        crashedImage!.width.toDouble(),
        crashedImage!.height.toDouble(),
      );
      canvas.drawImageRect(
        crashedImage!,
        src,
        crashRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      // Glowing pink outline around crashed face
      canvas.drawCircle(
        Offset.zero,
        crashSize / 2,
        Paint()
          ..color = const Color(0xFFFF4081)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Dizzy rotating stars above Paril
      for (int i = 0; i < 3; i++) {
        final starAngle = elapsedTime * 4.0 + (i * 2 * math.pi / 3);
        final starOffset = Offset(
          math.cos(starAngle) * 26,
          -16 + math.sin(starAngle) * 7,
        );
        canvas.drawCircle(
          starOffset,
          2.8,
          Paint()..color = const Color(0xFFFFD54F),
        );
      }
    } else if (birdImage != null) {
      // Draw actual paril_bird.png
      final src = Rect.fromLTWH(
        0,
        0,
        birdImage!.width.toDouble(),
        birdImage!.height.toDouble(),
      );
      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(birdImage!, src, birdRect, paint);
    } else {
      // Fallback stylized Paril Bird if image is loading
      _drawFallbackBird(canvas, targetWidth, targetHeight);
    }

    canvas.restore();
  }

  void _drawFallbackBird(Canvas canvas, double width, double height) {
    // Stylized flying hero fallback
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF9013FE)],
      ).createShader(Rect.fromLTWH(-width / 2, -height / 2, width, height));

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: width, height: height * 0.7),
      bodyPaint,
    );

    // Cape
    final capePaint = Paint()..color = const Color(0xFFFF4081);
    final capePath = Path()
      ..moveTo(-width * 0.3, 0)
      ..lineTo(-width * 0.6, height * 0.4)
      ..lineTo(-width * 0.2, height * 0.3)
      ..close();
    canvas.drawPath(capePath, capePaint);

    // Glowing face
    final facePaint = Paint()..color = const Color(0xFFFFE0B2);
    canvas.drawCircle(Offset(width * 0.25, -height * 0.1), 10, facePaint);
  }

  // ── 8. Floating Score Text Popups ─────────────────────────────────────────
  void _drawFloatingTexts(Canvas canvas) {
    for (final ft in floatingTexts) {
      if (ft.isDead) continue;
      final textSpan = TextSpan(
        text: ft.text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: ft.life.clamp(0.0, 1.0)),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: const Color(0xFFFF4081).withValues(alpha: ft.life.clamp(0.0, 1.0)),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(ft.x - tp.width / 2, ft.y - tp.height / 2));
    }
  }

  // ── 9. Lush Garden Ground ─────────────────────────────────────────────────
  void _drawGardenGround(Canvas canvas, Size size) {
    final groundTop = size.height - groundHeight;
    final groundRect = Rect.fromLTWH(0, groundTop, size.width, groundHeight);

    // Rich garden soil gradient
    final soilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2723), Color(0xFF271510), Color(0xFF1B0D0A)],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, soilPaint);

    // Top lush green grass strip
    final grassRect = Rect.fromLTWH(0, groundTop, size.width, 14);
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7CB342), Color(0xFF43A047), Color(0xFF2E7D32)],
      ).createShader(grassRect);
    canvas.drawRect(grassRect, grassPaint);

    // Scrolling grass blades and garden sprouts
    final bladePaint = Paint()
      ..color = const Color(0xFF9CCC65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final bladeSpacing = 16.0;
    final offset = groundOffset % bladeSpacing;
    for (double x = -bladeSpacing + offset; x < size.width + bladeSpacing; x += bladeSpacing) {
      final h = 6.0 + 4.0 * math.sin((x + groundOffset) * 0.1);
      canvas.drawLine(
        Offset(x, groundTop + 2),
        Offset(x + 2, groundTop - h),
        bladePaint,
      );
    }

    // Little flowers / carrots sprouting along ground
    final flowerPaint = Paint()..color = const Color(0xFFFF80AB);
    for (double x = -30.0 + (groundOffset % 60); x < size.width + 30; x += 60) {
      canvas.drawCircle(Offset(x, groundTop + 5), 2.5, flowerPaint);
    }

    // Top rim divider line
    final linePaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, groundTop), Offset(size.width, groundTop), linePaint);
  }

  @override
  bool shouldRepaint(covariant ParilBirdPainter oldDelegate) => true;
}
