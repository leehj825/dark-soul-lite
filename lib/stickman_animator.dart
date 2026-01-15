import 'dart:convert';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:stickman_3d/stickman_3d.dart';

class StickmanAnimator extends PositionComponent {
  final StickmanController controller;

  // View state
  double cameraYaw = 0.0;
  Vector2 velocity = Vector2.zero();
  double? facingAngleOverride;

  // Loading state
  bool _isLoaded = false;
  String? _pendingAnimation; // Fixes the race condition
  final Map<String, StickmanClip> _clips = {};

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final sapContent = await rootBundle.loadString('assets/data/animations.sap');

      if (sapContent.isNotEmpty) {
        final jsonMap = jsonDecode(sapContent);
        List<StickmanClip> loadedClips = [];
        if (jsonMap.containsKey('clips')) {
          loadedClips = (jsonMap['clips'] as List)
              .map((c) => StickmanClip.fromJson(c))
              .toList();
        } else if (jsonMap.containsKey('keyframes')) {
           loadedClips = [StickmanClip.fromJson(jsonMap)];
        }
        // STORE AND NORMALIZE NAMES
        for (var clip in loadedClips) {
          // Fix: Remove ".fbx" so "sword idle.fbx" becomes "sword idle"
          String cleanName = clip.name.replaceAll('.fbx', '');

          // Update the clip's internal name too
          // Note: StickmanClip might be immutable, so we just map the clean key
          _clips[cleanName] = clip;
        }
        debugPrint("✅ LOADED ANIMATIONS: ${_clips.keys.join(', ')}");
      }
      _isLoaded = true;

      // Fix: Play the animation that was requested while loading
      if (_pendingAnimation != null) {
        playAnimation(_pendingAnimation!);
        _pendingAnimation = null;
      }

      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("❌ ERROR loading animations: $e");
    }
  }

  void playAnimation(String name) {
    // 1. If not loaded yet, save for later
    if (!_isLoaded) {
      _pendingAnimation = name;
      return;
    }

    // 2. Play if found
    if (_clips.containsKey(name)) {
      final clip = _clips[name];
      if (controller.activeClip != clip) {
        controller.activeClip = clip;
        controller.isPlaying = true;
        controller.currentFrameIndex = 0;
        controller.setMode(EditorMode.animate);
      }
    } else {
      // Optional: fallback to fuzzy matching if exact match fails
      // debugPrint("⚠️ Animation '$name' not found. Available: ${_clips.keys.length}");
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;

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
    } catch (e) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded) return;
    controller.update(dt, velocity.x, velocity.y);
  }
}
