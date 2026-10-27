import 'package:flutter/material.dart';

/// Distinct vegetable obstacle themes.
enum VegetableType {
  carrot,
  broccoli,
  cucumber,
  eggplant;

  String get displayName {
    switch (this) {
      case VegetableType.carrot:
        return 'Carrot Wall';
      case VegetableType.broccoli:
        return 'Broccoli Wall';
      case VegetableType.cucumber:
        return 'Cucumber Wall';
      case VegetableType.eggplant:
        return 'Eggplant Wall';
    }
  }
}

/// A vertical obstacle pair made of vegetables.
class VegetableObstacle {
  VegetableObstacle({
    required this.x,
    required this.width,
    required this.topHeight,
    required this.gap,
    required this.type,
    this.passed = false,
  });

  double x;
  final double width;
  final double topHeight;
  final double gap;
  final VegetableType type;
  bool passed;

  Rect get topRect => Rect.fromLTWH(x, 0, width, topHeight);

  Rect bottomRect(double screenHeight, double groundHeight) {
    final bottomTop = topHeight + gap;
    final bottomHeight = (screenHeight - groundHeight) - bottomTop;
    return Rect.fromLTWH(x, bottomTop, width, bottomHeight > 0 ? bottomHeight : 0);
  }
}

/// Ice cream collectible bonus item.
class IceCreamBonus {
  IceCreamBonus({
    required this.x,
    required this.y,
    this.radius = 18.0,
    this.flavorIndex = 0,
    this.collected = false,
  });

  double x;
  double y;
  final double radius;
  final int flavorIndex;
  bool collected;

  Rect get bounds => Rect.fromCircle(center: Offset(x, y), radius: radius);
}

/// Dynamic particle for trail and collection effects.
class GameParticle {
  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.life = 1.0,
    this.decay = 0.03,
    this.isHeart = false,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double decay;
  bool isHeart;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= decay;
    if (life < 0) life = 0;
  }

  bool get isDead => life <= 0;
}

/// Floating reward text popup (e.g. "+5 🍦").
class FloatingScoreText {
  FloatingScoreText({
    required this.x,
    required this.y,
    required this.text,
    this.life = 1.0,
  });

  double x;
  double y;
  final String text;
  double life;

  void update(double dt) {
    y -= 40 * dt;
    life -= 1.2 * dt;
    if (life < 0) life = 0;
  }

  bool get isDead => life <= 0;
}
