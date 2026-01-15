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

  // INTERNAL STORAGE for animations (since Controller doesn't have a library)
  final Map<String, StickmanClip> _clips = {};

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      // 1. Load the file string
      final sapContent = await rootBundle.loadString('assets/data/animations.sap');

      // 2. Manually parse JSON (Bypassing StickmanPersistence)
      if (sapContent.isNotEmpty) {
        final jsonMap = jsonDecode(sapContent);

        List<StickmanClip> loadedClips = [];

        // Handle Project Format
        if (jsonMap.containsKey('clips')) {
          loadedClips = (jsonMap['clips'] as List)
              .map((c) => StickmanClip.fromJson(c))
              .toList();
        }
        // Handle Legacy Single-Clip Format
        else if (jsonMap.containsKey('keyframes')) {
           loadedClips = [StickmanClip.fromJson(jsonMap)];
        }

        // Store clips in our local map
        for (var clip in loadedClips) {
          _clips[clip.name] = clip;
        }

        debugPrint("Loaded ${_clips.length} animations: ${_clips.keys.join(', ')}");
      }

      _isLoaded = true;

      // Force update to prevent crashes
      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("Error initializing Stickman animations: $e");
    }
  }

  void playAnimation(String name) {
    // 1. Check if loaded
    if (!_isLoaded) return;

    // 2. Look up clip in OUR local map
    if (_clips.containsKey(name)) {
      final clip = _clips[name];

      // 3. Set the active clip on the controller directly
      controller.activeClip = clip;
      controller.isPlaying = true;
      controller.currentFrameIndex = 0;
      controller.setMode(EditorMode.animate);
    } else {
      // debugPrint("Animation '$name' not found.");
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;

    // Debug circle
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
      // Suppress render errors during loading
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded) return;
    controller.update(dt, velocity.x, velocity.y);
  }
}
