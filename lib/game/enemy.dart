import 'dart:ui';
import 'dart:math' as Math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '/game/dino_run.dart';
import '/models/enemy_data.dart';

// This represents a custom enemy in the game world.
class Enemy extends PositionComponent with CollisionCallbacks, HasGameReference<DinoRun> {
  // The data required for creation of this enemy.
  final EnemyData enemyData;

  // Animation variables
  double _animationTime = 0;
  double _rotationAngle = 0;
  double _bounceOffset = 0;
  bool _isSpinning = false;

  Enemy(this.enemyData) : super(size: Vector2.all(30));

  @override
  void onMount() {
    // Reduce the size of enemy as they look too
    // big compared to the dino.
    size *= 0.6;

    // Add a hitbox for this enemy.
    add(
      RectangleHitbox.relative(
        Vector2.all(0.8),
        parentSize: size,
        position: Vector2(size.x * 0.2, size.y * 0.2) / 2,
      ),
    );

    // Randomize enemy behavior
    _isSpinning = Math.Random().nextBool();

    super.onMount();
  }

  @override
  void update(double dt) {
    position.x -= enemyData.speedX * dt;

    // Remove the enemy and increase player score
    // by 1, if enemy has gone past left end of the screen.
    if (position.x < -enemyData.textureSize.x) {
      removeFromParent();
      if (game.playerData != null) {
        game.playerData!.currentScore += 1;
      }
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint();
    final center = Offset(size.x / 2, size.y / 2);

    // Simple, clean enemy design
    _drawSimpleEnemy(canvas, paint, center);
  }

  void _drawSimpleEnemy(Canvas canvas, Paint paint, Offset center) {
    // Simple shadow
    // paint.color = Colors.black.withOpacity(0.3);
    // canvas.drawCircle(Offset(center.dx + 2, center.dy + 12), 10, paint);

    // Main body - simple circle with gradient
    final bodyGradient = RadialGradient(
      colors: [Colors.red.shade400, Colors.red.shade700],
      stops: [0.0, 1.0],
    );
    paint.shader = bodyGradient.createShader(Rect.fromCircle(center: center, radius: 8));
    canvas.drawCircle(center, 8, paint);

    // Simple highlight
    paint.shader = null;
    paint.color = Colors.red.shade300;
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, paint);

    // Simple eyes
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 2, paint);
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 2, paint);

    // Simple pupils
    paint.color = Colors.black;
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 1, paint);
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 1, paint);

    // Simple mouth - just a line
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - 2, center.dy + 2),
      Offset(center.dx + 2, center.dy + 2),
      paint,
    );
  }
}
