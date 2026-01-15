import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runApp(MaterialApp(
    home: const GameWidget<SoulsStickmanGame>.controlled(
      gameFactory: SoulsStickmanGame.new,
    ),
  ));
}
