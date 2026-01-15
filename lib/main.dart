import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runZonedGuarded(() {
    runApp(const MaterialApp(
      home: GameWidget<SoulsStickmanGame>.controlled(
        gameFactory: SoulsStickmanGame.new,
      ),
    ));
  }, (error, stack) {
    debugPrint("CRASH ERROR: $error");
    debugPrint("STACK: $stack");
  });
}
