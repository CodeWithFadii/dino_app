import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:hive/hive.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as Math;

import '/game/dino.dart';
import '/widgets/hud.dart';
import '/models/settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_data.dart';
import '/widgets/pause_menu.dart';
import '/widgets/game_over_menu.dart';

// This is the main flame game class.
class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {
  DinoRun({super.camera});

  // List of all the image assets.
  static const _imageAssets = [
    'DinoSprites - tard.png',
    'AngryPig/Walk (36x30).png',
    'Bat/Flying (46x30).png',
    'Rino/Run (52x34).png',
  ];

  // List of all the audio assets.
  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  late Settings settings;
  late PlayerData playerData;
  late EnemyManager _enemyManager;

  // Flag to track where settings menu was opened from
  String? settingsReturnToOverlay;

  Vector2 get virtualSize => camera.viewport.virtualSize;

  // This method get called while flame is preparing this game.
  @override
  Future<void> onLoad() async {
    // Makes the game full screen and landscape only.
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    /// Read [PlayerData] and [Settings] from hive.
    playerData = await _readPlayerData();
    settings = await _readSettings();

    /// Initilize [AudioManager].
    await AudioManager.instance.init(_audioAssets, settings);

    // Start playing background music. Internally takes care
    // of checking user settings.
    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    // Cache all the images.
    await images.loadAll(_imageAssets);

    // This makes the camera look at the center of the viewport.
    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;

    // Add a beautiful animated background instead of simple colors
    final background = RectangleComponent(
      size: camera.viewport.virtualSize,
      paint: Paint()..color = const Color(0xFF87CEEB), // Sky blue base
    );
    camera.backdrop.add(background);

    // Add gradient sky effect
    final skyGradient = RectangleComponent(
      size: camera.viewport.virtualSize,
      paint: Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF87CEEB), // Sky blue
            const Color(0xFF98D8E8), // Lighter blue
            const Color(0xFFB0E0E6), // Powder blue
            const Color(0xFFE0F6FF), // Very light blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
            Rect.fromLTWH(0, 0, camera.viewport.virtualSize.x, camera.viewport.virtualSize.y)),
    );
    camera.backdrop.add(skyGradient);

    // Add gradient ground
    final groundGradient = RectangleComponent(
      size: Vector2(camera.viewport.virtualSize.x, 30),
      position: Vector2(0, camera.viewport.virtualSize.y - 30),
      paint: Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF8B4513), // Brown
            const Color(0xFFA0522D), // Sienna
            const Color(0xFFCD853F), // Peru
            const Color(0xFFDEB887), // Burlywood
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(
            0, camera.viewport.virtualSize.y - 30, camera.viewport.virtualSize.x, 30)),
    );
    camera.backdrop.add(groundGradient);

    // Add grass details on ground
    for (int i = 0; i < 20; i++) {
      final grass = _createGrass(
        position: Vector2(
          (i * 20) + (Math.Random().nextDouble() * 10),
          camera.viewport.virtualSize.y - 25,
        ),
        height: (Math.Random().nextDouble() * 8) + 5,
      );
      camera.backdrop.add(grass);
    }

    // Add distant mountains
    // final mountains = _createMountains();
    // camera.backdrop.add(mountains);

    // Add sun with glow effect
    final sun = _createSun();
    camera.backdrop.add(sun);
  }

  // Create grass component
  Component _createGrass({required Vector2 position, required double height}) {
    return PositionComponent(
      position: position,
      size: Vector2(2, height),
    )..add(
        CustomPainterComponent(
          painter: GrassPainter(height: height),
        ),
      );
  }

  // // Create mountains component
  // Component _createMountains() {
  //   return PositionComponent(
  //     position: Vector2(0, camera.viewport.virtualSize.y - 80),
  //     size: Vector2(camera.viewport.virtualSize.x, 80),
  //   )..add(
  //       CustomPainterComponent(
  //         painter: MountainsPainter(),
  //       ),
  //     );
  // }

  // Create sun component
  Component _createSun() {
    return PositionComponent(
      position: Vector2(camera.viewport.virtualSize.x - 60, 40),
      size: Vector2.all(40),
    )..add(
        CustomPainterComponent(
          painter: SunPainter(),
        ),
      );
  }

  /// This method add the already created [Dino]
  /// and [EnemyManager] to this game.
  void startGamePlay() {
    _dino = Dino(playerData);
    _enemyManager = EnemyManager();

    world.add(_dino);
    world.add(_enemyManager);
  }

  // This method remove all the actors from the game.
  void _disconnectActors() {
    _dino.removeFromParent();
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
  }

  // This method reset the whole game world to initial state.
  void reset() {
    // First disconnect all actions from game world.
    _disconnectActors();

    // Reset player data to inital values.
    playerData.currentScore = 0;
    playerData.lives = 5;
  }

  // This method gets called for each tick/frame of the game.
  @override
  void update(double dt) {
    // If number of lives is 0 or less, game is over.
    if (playerData.lives <= 0) {
      overlays.add(GameOverMenu.id);
      overlays.remove(Hud.id);
      pauseEngine();
      AudioManager.instance.pauseBgm();
    }
    super.update(dt);
  }

  // This will get called for each tap on the screen.
  @override
  void onTapDown(TapDownInfo info) {
    // Make dino jump only when game is playing.
    // When game is in playing state, only Hud will be the active overlay.
    if (overlays.isActive(Hud.id)) {
      _dino.jump();
    }
    super.onTapDown(info);
  }

  /// This method reads [PlayerData] from the hive box.
  Future<PlayerData> _readPlayerData() async {
    final playerDataBox = await Hive.openBox<PlayerData>('DinoRun.PlayerDataBox');
    final playerData = playerDataBox.get('DinoRun.PlayerData');

    // If data is null, this is probably a fresh launch of the game.
    if (playerData == null) {
      // In such cases store default values in hive.
      await playerDataBox.put('DinoRun.PlayerData', PlayerData());
    }

    // Now it is safe to return the stored value.
    return playerDataBox.get('DinoRun.PlayerData')!;
  }

  /// This method reads [Settings] from the hive box.
  Future<Settings> _readSettings() async {
    final settingsBox = await Hive.openBox<Settings>('DinoRun.SettingsBox');
    final settings = settingsBox.get('DinoRun.Settings');

    // If data is null, this is probably a fresh launch of the game.
    if (settings == null) {
      // In such cases store default values in hive.
      await settingsBox.put(
        'DinoRun.Settings',
        Settings(bgm: true, sfx: true),
      );
    }

    // Now it is safe to return the stored value.
    return settingsBox.get('DinoRun.Settings')!;
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // On resume, if active overlay is not PauseMenu,
        // resume the engine (lets the parallax effect play).
        if (!(overlays.isActive(PauseMenu.id)) && !(overlays.isActive(GameOverMenu.id))) {
          resumeEngine();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // If game is active, then remove Hud and add PauseMenu
        // before pausing the game.
        if (overlays.isActive(Hud.id)) {
          overlays.remove(Hud.id);
          overlays.add(PauseMenu.id);
        }
        pauseEngine();
        break;
    }
    super.lifecycleStateChange(state);
  }
}

// Custom painter for grass
class GrassPainter extends CustomPainter {
  final double height;

  GrassPainter({required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    // GRASS GRADIENT for realistic look
    final grassGradient = LinearGradient(
      colors: [
        Colors.green.shade400,
        Colors.green.shade500,
        Colors.green.shade600,
        Colors.green.shade700,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paint = Paint()
      ..shader = grassGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw grass blade with CURVED SHAPE
    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.quadraticBezierTo(
        size.width / 2 - 2, size.height - height * 0.7, size.width / 2 - 1, size.height - height);
    path.quadraticBezierTo(
        size.width / 2, size.height - height * 0.8, size.width / 2 + 1, size.height - height);
    path.quadraticBezierTo(
        size.width / 2 + 2, size.height - height * 0.7, size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // GRASS HIGHLIGHT for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.green.shade300.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(size.width / 2, size.height);
    highlightPath.quadraticBezierTo(size.width / 2 - 0.5, size.height - height * 0.7,
        size.width / 2 - 0.3, size.height - height);
    highlightPath.quadraticBezierTo(
        size.width / 2, size.height - height * 0.8, size.width / 2 + 0.3, size.height - height);
    highlightPath.quadraticBezierTo(
        size.width / 2 + 0.5, size.height - height * 0.7, size.width / 2, size.height);
    highlightPath.close();

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for mountains
class MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // MOUNTAIN GRADIENT for incredible depth
    final mountainGradient = LinearGradient(
      colors: [
        Colors.grey.shade600,
        Colors.grey.shade700,
        Colors.grey.shade800,
        Colors.grey.shade900,
        Colors.black,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paint = Paint()
      ..shader = mountainGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw INCREDIBLE MOUNTAIN PEAKS with realistic shapes
    final path = Path();
    path.moveTo(0, size.height);

    // Multiple mountain peaks with VARYING HEIGHTS and SHAPES
    path.lineTo(15, size.height - 65);
    path.lineTo(25, size.height - 55);
    path.lineTo(35, size.height - 70);
    path.lineTo(45, size.height - 45);
    path.lineTo(55, size.height - 75);
    path.lineTo(65, size.height - 40);
    path.lineTo(75, size.height - 80);
    path.lineTo(85, size.height - 35);
    path.lineTo(95, size.height - 70);
    path.lineTo(105, size.height - 50);
    path.lineTo(115, size.height - 85);
    path.lineTo(125, size.height - 45);
    path.lineTo(135, size.height - 75);
    path.lineTo(145, size.height - 60);
    path.lineTo(155, size.height - 90);
    path.lineTo(165, size.height - 40);
    path.lineTo(175, size.height - 70);
    path.lineTo(185, size.height - 55);
    path.lineTo(195, size.height - 80);
    path.lineTo(205, size.height - 50);
    path.lineTo(215, size.height - 75);
    path.lineTo(225, size.height - 45);
    path.lineTo(235, size.height - 70);
    path.lineTo(245, size.height - 60);
    path.lineTo(255, size.height - 85);
    path.lineTo(265, size.height - 40);
    path.lineTo(275, size.height - 75);
    path.lineTo(285, size.height - 55);
    path.lineTo(295, size.height - 80);
    path.lineTo(305, size.height - 50);
    path.lineTo(315, size.height - 70);
    path.lineTo(325, size.height - 45);
    path.lineTo(335, size.height - 65);
    path.lineTo(345, size.height - 55);
    path.lineTo(355, size.height - 75);
    path.lineTo(365, size.height - 50);

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // MOUNTAIN HIGHLIGHTS for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.grey.shade500.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(0, size.height);

    // Highlights on peaks
    highlightPath.lineTo(15, size.height - 60);
    highlightPath.lineTo(25, size.height - 50);
    highlightPath.lineTo(35, size.height - 65);
    highlightPath.lineTo(45, size.height - 40);
    highlightPath.lineTo(55, size.height - 70);
    highlightPath.lineTo(65, size.height - 35);
    highlightPath.lineTo(75, size.height - 75);
    highlightPath.lineTo(85, size.height - 30);
    highlightPath.lineTo(95, size.height - 65);
    highlightPath.lineTo(105, size.height - 45);
    highlightPath.lineTo(115, size.height - 80);
    highlightPath.lineTo(125, size.height - 40);
    highlightPath.lineTo(135, size.height - 70);
    highlightPath.lineTo(145, size.height - 55);
    highlightPath.lineTo(155, size.height - 85);
    highlightPath.lineTo(165, size.height - 35);
    highlightPath.lineTo(175, size.height - 65);
    highlightPath.lineTo(185, size.height - 50);
    highlightPath.lineTo(195, size.height - 75);
    highlightPath.lineTo(205, size.height - 45);
    highlightPath.lineTo(215, size.height - 70);
    highlightPath.lineTo(225, size.height - 40);
    highlightPath.lineTo(235, size.height - 65);
    highlightPath.lineTo(245, size.height - 55);
    highlightPath.lineTo(255, size.height - 80);
    highlightPath.lineTo(265, size.height - 35);
    highlightPath.lineTo(275, size.height - 70);
    highlightPath.lineTo(285, size.height - 50);
    highlightPath.lineTo(295, size.height - 75);
    highlightPath.lineTo(305, size.height - 45);
    highlightPath.lineTo(315, size.height - 65);
    highlightPath.lineTo(325, size.height - 40);
    highlightPath.lineTo(335, size.height - 60);
    highlightPath.lineTo(345, size.height - 50);
    highlightPath.lineTo(355, size.height - 70);
    highlightPath.lineTo(365, size.height - 45);

    highlightPath.lineTo(size.width, size.height);
    highlightPath.close();

    canvas.drawPath(highlightPath, highlightPaint);

    // SNOW CAPS on highest peaks
    final snowPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Snow on the highest peaks
    canvas.drawCircle(Offset(75, size.height - 80), 3, snowPaint);
    canvas.drawCircle(Offset(115, size.height - 85), 3, snowPaint);
    canvas.drawCircle(Offset(155, size.height - 90), 4, snowPaint);
    canvas.drawCircle(Offset(255, size.height - 80), 3, snowPaint);
    canvas.drawCircle(Offset(355, size.height - 75), 3, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for sun
class SunPainter extends CustomPainter {
  double _time = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // INCREDIBLE SUN GLOW EFFECT
    final glowGradient = RadialGradient(
      colors: [
        Colors.yellow.withOpacity(0.6),
        Colors.yellow.withOpacity(0.4),
        Colors.yellow.withOpacity(0.2),
        Colors.yellow.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: [0.0, 0.3, 0.6, 0.8, 1.0],
    );

    final glowPaint = Paint()
      ..shader = glowGradient.createShader(Rect.fromCircle(center: center, radius: radius + 8));
    canvas.drawCircle(center, radius + 8, glowPaint);

    // Main sun with INCREDIBLE GRADIENT
    final sunGradient = RadialGradient(
      colors: [
        Colors.yellow.shade200,
        Colors.yellow.shade300,
        Colors.yellow.shade400,
        Colors.yellow.shade500,
        Colors.yellow.shade600,
        Colors.orange.shade400,
        Colors.orange.shade500,
      ],
      stops: [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
    );

    final paint = Paint()
      ..shader = sunGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);

    // SUN HIGHLIGHT for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.yellow.shade100.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius * 0.4, highlightPaint);

    // SUN RAYS - INCREDIBLE ENERGY
    final rayGradient = LinearGradient(
      colors: [
        Colors.yellow.withOpacity(0.8),
        Colors.yellow.withOpacity(0.6),
        Colors.yellow.withOpacity(0.4),
        Colors.yellow.withOpacity(0.2),
        Colors.transparent,
      ],
      begin: Alignment.center,
      end: Alignment.centerRight,
    );

    final rayPaint = Paint()
      ..shader = rayGradient.createShader(Rect.fromCircle(center: center, radius: radius + 12))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Multiple ray layers for INCREDIBLE EFFECT
    for (int i = 0; i < 12; i++) {
      final angle = (i * Math.pi / 6) + _time;
      final startPoint = Offset(
        center.dx + Math.cos(angle) * (radius + 2),
        center.dy + Math.sin(angle) * (radius + 2),
      );
      final endPoint = Offset(
        center.dx + Math.cos(angle) * (radius + 12),
        center.dy + Math.sin(angle) * (radius + 12),
      );
      canvas.drawLine(startPoint, endPoint, rayPaint);
    }

    // Additional shorter rays
    final shortRayPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * Math.pi / 4) + _time + 0.5;
      final startPoint = Offset(
        center.dx + Math.cos(angle) * (radius + 1),
        center.dy + Math.sin(angle) * (radius + 1),
      );
      final endPoint = Offset(
        center.dx + Math.cos(angle) * (radius + 8),
        center.dy + Math.sin(angle) * (radius + 8),
      );
      canvas.drawLine(startPoint, endPoint, shortRayPaint);
    }

    // ENERGY PARTICLES around sun
    final particlePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * Math.pi / 3) + _time * 2;
      final particlePos = Offset(
        center.dx + Math.cos(angle) * (radius + 15),
        center.dy + Math.sin(angle) * (radius + 15),
      );
      canvas.drawCircle(particlePos, 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
