import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemChrome
import 'game.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Force Landscape and Full Screen (Immersive Mode)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    runApp(
      // 2. Use GameWidget directly as the root to ensure it fills the screen
      GameWidget<SoulsStickmanGame>.controlled(
        gameFactory: SoulsStickmanGame.new,
      ),
    );
  }, (error, stack) {
    debugPrint("ERROR: $error");
  });
}
