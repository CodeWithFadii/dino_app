import 'dart:ui';
import 'dart:math' as Math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '/game/enemy.dart';
import '/game/dino_run.dart';
import '/game/audio_manager.dart';
import '/models/player_data.dart';

/// This enum represents the animation states of [Dino].
enum DinoAnimationStates {
  idle,
  run,
  kick,
  hit,
  sprint,
}

// This represents the custom character of this game.
class Dino extends PositionComponent with CollisionCallbacks, HasGameReference<DinoRun> {
  // The max distance from top of the screen beyond which
  // dino should never go. Basically the screen height - ground height
  double yMax = 0.0;

  // Dino's current speed along y-axis.
  double speedY = 0.0;

  // Controlls how long the hit animations will be played.
  final Timer _hitTimer = Timer(1);

  static const double gravity = 800;

  final PlayerData playerData;

  bool isHit = false;
  DinoAnimationStates current = DinoAnimationStates.run;

  // Animation variables
  double _animationTime = 0;
  double _bounceOffset = 0;
  bool _isMoving = true;

  Dino(this.playerData) : super(size: Vector2.all(24));

  @override
  void onMount() {
    // First reset all the important properties, because onMount()
    // will be called even while restarting the game.
    _reset();

    // Add a hitbox for dino.
    add(
      RectangleHitbox.relative(
        Vector2(0.5, 0.7),
        parentSize: size,
        position: Vector2(size.x * 0.5, size.y * 0.3) / 2,
      ),
    );
    yMax = y;

    /// Set the callback for [_hitTimer].
    _hitTimer.onTick = () {
      current = DinoAnimationStates.run;
      isHit = false;
    };

    super.onMount();
  }

  @override
  void update(double dt) {
    // v = u + at
    speedY += gravity * dt;

    // d = s0 + s * t
    y += speedY * dt;

    /// This code makes sure that dino never goes beyond [yMax].
    if (isOnGround) {
      y = yMax;
      speedY = 0.0;
      if ((current != DinoAnimationStates.hit) && (current != DinoAnimationStates.run)) {
        current = DinoAnimationStates.run;
      }
    }

    _hitTimer.update(dt);

    // Update animation time
    _animationTime += dt;
    if (_isMoving) {
      _bounceOffset = (Math.sin(_animationTime * 8) * 2).toDouble();
    }

    super.update(dt);
  }

  // Gets called when dino collides with other Collidables.
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Call hit only if other component is an Enemy and dino
    // is not already in hit state.
    if ((other is Enemy) && (!isHit)) {
      hit();
    }
    super.onCollision(intersectionPoints, other);
  }

  // Returns true if dino is on ground.
  bool get isOnGround => (y >= yMax);

  // Makes the dino jump.
  void jump() {
    // Jump only if dino is on ground.
    if (isOnGround) {
      speedY = -300;
      current = DinoAnimationStates.idle;
      AudioManager.instance.playSfx('jump14.wav');
    }
  }

  // This method changes the animation state to
  /// [DinoAnimationStates.hit], plays the hit sound
  /// effect and reduces the player life by 1.
  void hit() {
    isHit = true;
    AudioManager.instance.playSfx('hurt7.wav');
    current = DinoAnimationStates.hit;
    _hitTimer.start();
    if (playerData != null) {
      playerData!.lives -= 1;
    }
  }

  // This method reset some of the important properties
  // of this component back to normal.
  void _reset() {
    if (isMounted) {
      removeFromParent();
    }
    anchor = Anchor.bottomLeft;
    position = Vector2(32, game.virtualSize.y - 22);
    size = Vector2.all(24);
    current = DinoAnimationStates.run;
    isHit = false;
    speedY = 0.0;
    _animationTime = 0;
    _bounceOffset = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint();
    final center = Offset(size.x / 2, size.y / 2);

    // Draw the custom character based on state
    switch (current) {
      case DinoAnimationStates.run:
        _drawRunningCharacter(canvas, paint, center);
        break;
      case DinoAnimationStates.idle:
        _drawIdleCharacter(canvas, paint, center);
        break;
      case DinoAnimationStates.hit:
        _drawHitCharacter(canvas, paint, center);
        break;
      default:
        _drawRunningCharacter(canvas, paint, center);
    }
  }

  void _drawRunningCharacter(Canvas canvas, Paint paint, Offset center) {
    // // Shadow
    // paint.color = Colors.black.withOpacity(0.3);
    // canvas.drawCircle(Offset(center.dx + 2, center.dy + 12), 10, paint);

    // Body gradient (main circle)
    final bodyGradient = RadialGradient(
      colors: [Colors.blue.shade400, Colors.blue.shade700],
      stops: [0.0, 1.0],
    );
    paint.shader = bodyGradient.createShader(Rect.fromCircle(center: center, radius: 8));
    canvas.drawCircle(center, 8, paint);

    // Body highlight
    paint.shader = null;
    paint.color = Colors.blue.shade200;
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, paint);

    // Eyes with better detail
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 2.5, paint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 2.5, paint);

    // Eye shadows
    paint.color = Colors.blue.shade800;
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 1.5), 2.5, paint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 1.5), 2.5, paint);

    // Pupils with shine
    paint.color = Colors.black;
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 1.5, paint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 1.5, paint);

    // Eye shine
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx + 1.5, center.dy - 2.5), 0.8, paint);
    canvas.drawCircle(Offset(center.dx - 1.5, center.dy - 2.5), 0.8, paint);

    // Happy smile with gradient
    paint.shader = LinearGradient(
      colors: [Colors.white, Colors.blue.shade200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(center: center, width: 8, height: 8));
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 8, height: 8),
      0,
      3.14,
      false,
      paint,
    );

    // Bouncing effect
    final bounceCenter = Offset(center.dx, center.dy + _bounceOffset);

    // Legs with gradient and shadows
    paint.shader = LinearGradient(
      colors: [Colors.blue.shade500, Colors.blue.shade800],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromCenter(center: bounceCenter, width: 4, height: 8));
    paint.style = PaintingStyle.fill;

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(bounceCenter.dx - 3, bounceCenter.dy + 8), width: 2.5, height: 4),
        const Radius.circular(1),
      ),
      paint,
    );

    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(bounceCenter.dx + 3, bounceCenter.dy + 8), width: 2.5, height: 4),
        const Radius.circular(1),
      ),
      paint,
    );

    // Arms with gradient
    paint.shader = LinearGradient(
      colors: [Colors.blue.shade400, Colors.blue.shade600],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromCenter(center: bounceCenter, width: 6, height: 3));

    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(bounceCenter.dx - 6, bounceCenter.dy - 2), width: 2.5, height: 3),
        const Radius.circular(1),
      ),
      paint,
    );

    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(bounceCenter.dx + 6, bounceCenter.dy - 2), width: 2.5, height: 3),
        const Radius.circular(1),
      ),
      paint,
    );

    // Energy particles when running
    if (_isMoving) {
      paint.shader = null;
      paint.color = Colors.cyan.withOpacity(0.8);
      final particleOffset = (Math.sin(_animationTime * 15) * 3).toDouble();
      canvas.drawCircle(Offset(bounceCenter.dx - 8, bounceCenter.dy + particleOffset), 1, paint);
      canvas.drawCircle(Offset(bounceCenter.dx + 8, bounceCenter.dy - particleOffset), 1, paint);
    }
  }

  void _drawIdleCharacter(Canvas canvas, Paint paint, Offset center) {
    // Body (main circle)
    paint.color = Colors.blue;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, paint);

    // Eyes (bigger for idle state)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 2.5, paint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 2.5, paint);

    // Pupils
    paint.color = Colors.black;
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 2), 1.5, paint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 1.5, paint);

    // Surprised mouth
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + 2), 1.5, paint);

    // Legs (straight)
    paint.color = Colors.blue;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx - 3, center.dy + 8), width: 2, height: 4),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx + 3, center.dy + 8), width: 2, height: 4),
      paint,
    );

    // Arms (up in the air)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx - 6, center.dy - 4), width: 2, height: 3),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx + 6, center.dy - 4), width: 2, height: 3),
      paint,
    );
  }

  void _drawHitCharacter(Canvas canvas, Paint paint, Offset center) {
    // Body (main circle) - red when hit
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, paint);

    // X eyes (hurt)
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    // Left X eye
    canvas.drawLine(
      Offset(center.dx - 3, center.dy - 3),
      Offset(center.dx - 1, center.dy - 1),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 1, center.dy - 3),
      Offset(center.dx - 3, center.dy - 1),
      paint,
    );

    // Right X eye
    canvas.drawLine(
      Offset(center.dx + 1, center.dy - 3),
      Offset(center.dx + 3, center.dy - 1),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + 3, center.dy - 3),
      Offset(center.dx + 1, center.dy - 1),
      paint,
    );

    // Sad mouth
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 8, height: 8),
      3.14,
      3.14,
      false,
      paint,
    );

    // Legs (shaking)
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    final shakeOffset = (Math.sin(_animationTime * 20) * 1).toDouble();

    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx - 3 + shakeOffset, center.dy + 8), width: 2, height: 4),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx + 3 - shakeOffset, center.dy + 8), width: 2, height: 4),
      paint,
    );

    // Arms (down)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx - 6, center.dy + 2), width: 2, height: 3),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx + 6, center.dy + 2), width: 2, height: 3),
      paint,
    );
  }
}
