import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runZonedGuarded(() {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Scaffold(
        body: GameWidget<SoulsStickmanGame>.controlled(
          gameFactory: SoulsStickmanGame.new,
        ),
      ),
    ));
  }, (error, stack) {
    debugPrint("ERROR: $error");
  });
}
