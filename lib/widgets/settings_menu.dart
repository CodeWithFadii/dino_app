import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/game/dino_run.dart';
import '/models/settings.dart';
import '/models/player_data.dart';
import '/widgets/main_menu.dart';
import '/game/audio_manager.dart';
import 'package:hive/hive.dart';

// This represents the settings menu overlay.
class SettingsMenu extends StatelessWidget {
  // An unique identified for this overlay.
  static const id = 'SettingsMenu';

  // Reference to parent game.
  final DinoRun game;

  const SettingsMenu(this.game, {super.key});

  void _showPurchaseDialog(
      BuildContext context, String packageName, int coins, double price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withAlpha(200),
          title: Text(
            'Purchase $packageName',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: Text(
            'Get $coins coins for \$${price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // TODO: Implement actual IAP here
                // For now, just add coins for testing
                final playerData =
                    Provider.of<PlayerData>(context, listen: false);
                playerData.addCoins(coins);

                // Save to Hive and update the game's PlayerData
                try {
                  final playerDataBox =
                      Hive.box<PlayerData>('DinoRun.PlayerDataBox');
                  await playerDataBox.put('DinoRun.PlayerData', playerData);

                  // Update the game's PlayerData to reflect the changes
                  game.playerData.coins = playerData.coins;
                  game.playerData.notifyListeners();
                } catch (e) {
                  print('Error saving to Hive: $e');
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully purchased $coins coins!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Purchase',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: game.settings,
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: Colors.black.withAlpha(100),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // const Text(
                    //   'Settings',
                    //   style: TextStyle(
                    //     fontSize: 40,
                    //     color: Colors.white,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    // Coin display
                    // Audio Settings
                    // const Text(
                    //   'Audio Settings',
                    //   style: TextStyle(
                    //     fontSize: 25,
                    //     color: Colors.white,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // const SizedBox(height: 15),
                    // Selector<Settings, bool>(
                    //   selector: (_, settings) => settings.bgm,
                    //   builder: (context, bgm, __) {
                    //     return SwitchListTile(
                    //       title: const Text(
                    //         'Music',
                    //         style: TextStyle(
                    //           fontSize: 25,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       value: bgm,
                    //       onChanged: (bool value) {
                    //         Provider.of<Settings>(context, listen: false).bgm = value;
                    //         if (value) {
                    //           AudioManager.instance.startBgm('8BitPlatformerLoop.wav');
                    //         } else {
                    //           AudioManager.instance.stopBgm();
                    //         }
                    //       },
                    //     );
                    //   },
                    // ),
                    // Selector<Settings, bool>(
                    //   selector: (_, settings) => settings.sfx,
                    //   builder: (context, sfx, __) {
                    //     return SwitchListTile(
                    //       title: const Text(
                    //         'Effects',
                    //         style: TextStyle(
                    //           fontSize: 25,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       value: sfx,
                    //       onChanged: (bool value) {
                    //         Provider.of<Settings>(context, listen: false).sfx = value;
                    //       },
                    //     );
                    //   },
                    // ),
                    // const SizedBox(height: 30),
                    // In-App Purchases
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            game.overlays.remove(SettingsMenu.id);
                            // Return to the appropriate overlay based on where we came from
                            if (game.settingsReturnToOverlay != null) {
                              game.overlays.add(game.settingsReturnToOverlay!);
                              game.settingsReturnToOverlay =
                                  null; // Clear the flag
                            } else {
                              game.overlays.add(MainMenu.id);
                            }
                          },
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const Text(
                          'Purchase Coins',
                            style: TextStyle(
                            fontSize: 25,
                              color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextButton(onPressed: null, child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPurchaseOption(
                                context, 'Starter Pack', 100, 1.0),
                            _buildPurchaseOption(
                                context, 'Small Pack', 200, 2.0),
                            _buildPurchaseOption(
                                context, 'Medium Pack', 300, 3.0),
                            _buildPurchaseOption(
                                context, 'Large Pack', 400, 4.0),
                            _buildPurchaseOption(
                                context, 'Mega Pack', 500, 5.0),
                          ],
                        ),
                      ),
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

  Widget _buildPurchaseOption(
      BuildContext context, String name, int coins, double price) {
    return Card(
      color: Colors.amber.withAlpha(100),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        leading:
            const Icon(Icons.monetization_on, color: Colors.amber, size: 30),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$coins coins - \$${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showPurchaseDialog(context, name, coins, price),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Buy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
