import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/widgets/hud.dart';
import '/game/dino_run.dart';
import '/widgets/main_menu.dart';
import '/models/player_data.dart';
import '/widgets/pause_menu.dart';
import '/widgets/settings_menu.dart';
import '/game/audio_manager.dart';
import 'package:hive/hive.dart';

// This represents the game over overlay,
// displayed with dino runs out of lives.
class GameOverMenu extends StatelessWidget {
  // An unique identified for this overlay.
  static const id = 'GameOverMenu';

  // Reference to parent game.
  final DinoRun game;

  const GameOverMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: game.playerData,
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.black.withAlpha(100),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                child: Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    const Text(
                      'Game Over',
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    Selector<PlayerData, int>(
                      selector: (_, playerData) => playerData.currentScore,
                      builder: (_, score, __) {
                        return Text(
                          'You Score: $score',
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        );
                      },
                    ),
                    // Coin display
                    Selector<PlayerData, int>(
                      selector: (_, playerData) => playerData.coins,
                      builder: (_, coins, __) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 30),
                            const SizedBox(width: 8),
                            Text(
                              '$coins',
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                    // Restart and Continue buttons in a row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          child: const Text(
                            'Restart',
                            style: TextStyle(
                              fontSize: 25,
                            ),
                          ),
                          onPressed: () {
                            game.overlays.remove(GameOverMenu.id);
                            game.overlays.add(Hud.id);
                            game.resumeEngine();
                            game.reset();
                            game.startGamePlay();
                            AudioManager.instance.resumeBgm();
                          },
                        ),
                        const SizedBox(width: 20),
                        Consumer<PlayerData>(
                          builder: (context, playerData, child) {
                            return Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  maxLines: 1,
                                  '(20 Coins)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                                  ),
                                  onPressed: playerData.coins >= 20
                                      ? () async {
                                          if (playerData.useCoins(20)) {
                                            // Save to Hive
                                            try {
                                              final playerDataBox =
                                                  Hive.box<PlayerData>('DinoRun.PlayerDataBox');
                                              await playerDataBox.put(
                                                  'DinoRun.PlayerData', playerData);

                                              // Update the game's PlayerData to reflect the changes
                                              game.playerData.coins = playerData.coins;
                                              game.playerData.notifyListeners();
                                            } catch (e) {
                                              print('Error saving to Hive: $e');
                                            }

                                            game.overlays.remove(GameOverMenu.id);
                                            game.overlays.add(Hud.id);
                                            game.resumeEngine();
                                            // Restore lives to continue the game
                                            playerData.lives = 5;
                                            AudioManager.instance.resumeBgm();
                                          }
                                        }
                                      : () {
                                          // Navigate to purchase section
                                          game.settingsReturnToOverlay = GameOverMenu.id;
                                          game.overlays.remove(GameOverMenu.id);
                                          game.overlays.add(SettingsMenu.id);

                                          // Show snackbar
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Not enough coins! Navigated to purchase section.'),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    maxLines: 1,
                                    'Continue',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                      onPressed: () {
                        game.overlays.remove(GameOverMenu.id);
                        game.overlays.add(MainMenu.id);
                        game.resumeEngine();
                        game.reset();
                        AudioManager.instance.resumeBgm();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
