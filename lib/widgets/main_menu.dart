import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/hud.dart';
import '/game/dino_run.dart';
import '/widgets/settings_menu.dart';

// This represents the main menu overlay.
class MainMenu extends StatelessWidget {
  // An unique identified for this overlay.
  static const id = 'MainMenu';

  // Reference to parent game.
  final DinoRun game;

  const MainMenu(this.game, {super.key});

  Future<void> open({required String playStoreLink}) async {
    try {
      final Uri url = Uri.parse(playStoreLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {}
    } catch (e) {
      log('Error opening Play Store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                    'Pod Runner',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    spacing: 20,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          game.startGamePlay();
                          game.playerData.lives = 3;
                          game.overlays.remove(MainMenu.id);
                          game.overlays.add(Hud.id);
                        },
                        child: const Text(
                          'Play',
                          style: TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          open(
                              playStoreLink:
                                  'https://sites.google.com/view/pod-runner-privacy-policy');
                        },
                        child: const Text(
                          'Policy',
                          style: TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      game.overlays.remove(MainMenu.id);
                      game.overlays.add(SettingsMenu.id);
                    },
                    child: const Text(
                      'Purchase',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
