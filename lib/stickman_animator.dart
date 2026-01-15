import 'dart:convert';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:stickman_3d/stickman_3d.dart';

class StickmanAnimator extends PositionComponent {
  final StickmanController controller;

  // Camera/View state
  double cameraYaw = 0.0;
  Vector2 velocity = Vector2.zero();
  double? facingAngleOverride;

  bool _isLoaded = false;

  // Internal storage for clips since we are manually managing them
  final Map<String, StickmanClip> _clips = {};

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      // 1. Load the file content as a string
      final sapContent = await rootBundle.loadString('assets/data/animations.sap');

      // 2. Manually parse the JSON (Fixes the build error)
      if (sapContent.isNotEmpty) {
        final jsonMap = jsonDecode(sapContent);
        List<StickmanClip> loadedClips = [];
        // Handle standard project format
        if (jsonMap.containsKey('clips')) {
          loadedClips = (jsonMap['clips'] as List)
              .map((c) => StickmanClip.fromJson(c))
              .toList();
        }
        // Handle single clip format
        else if (jsonMap.containsKey('keyframes')) {
           loadedClips = [StickmanClip.fromJson(jsonMap)];
        }
        // 3. Store clips in our local map
        for (var clip in loadedClips) {
          _clips[clip.name] = clip;
        }
        debugPrint("Stickman Loaded: ${_clips.length} animations found.");
      }
      _isLoaded = true;
      // 4. Force initial update to prevent render crash
      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("CRITICAL ERROR loading animations: $e");
    }
  }

  void playAnimation(String name) {
    if (!_isLoaded) return;

    // Look up the clip in our manually loaded map
    if (_clips.containsKey(name)) {
      final clip = _clips[name];
      // Apply to controller
      if (controller.activeClip?.name != name) {
        controller.activeClip = clip;
        controller.isPlaying = true;
        controller.currentFrameIndex = 0;
        controller.setMode(EditorMode.animate);
      }
    } else {
      // debugPrint("Animation '$name' not found.");
    }
  }

  @override
  void render(Canvas canvas) {
    // Prevent rendering before data is ready (Fixes Gray Screen)
    if (!_isLoaded) return;

    // Debug visual
    // canvas.drawCircle(Offset(size.x/2, size.y/2), 10, Paint()..color = Colors.cyan);
    try {
      double stickmanFacing = facingAngleOverride ?? controller.facingAngle;
      double viewRotationY = stickmanFacing - cameraYaw;
      const double viewRotationX = -pi / 10;
      final painter = StickmanPainter(
        controller: controller,
        viewRotationX: viewRotationX,
        viewRotationY: viewRotationY,
        cameraView: CameraView.free,
      );
      painter.paint(canvas, size.toSize());
    } catch (e) {
      // Suppress transient render errors
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded) return;

    // Update the physics/animation controller
    controller.update(dt, velocity.x, velocity.y);
  }
}
