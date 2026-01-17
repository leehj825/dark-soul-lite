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
  String? _pendingAnimation;
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

        // ---------------------------------------------------------
        // 1. LOAD SKELETON (This fixes the "Default Stickman" issue)
        // ---------------------------------------------------------
        if (jsonMap.containsKey('skeleton')) {
          try {
            // Create the custom skeleton from JSON
            final customSkeleton = StickmanSkeleton.fromJson(jsonMap['skeleton']);

            // FIX: Use lerp(1.0) to copy values instead of reassignment
            controller.skeleton.lerp(customSkeleton, 1.0);

            debugPrint("✅ LOADED CUSTOM SKELETON");
          } catch (e) {
            debugPrint("⚠️ Failed to load skeleton: $e");
          }
        }

        // ---------------------------------------------------------
        // 2. LOAD ANIMATIONS
        // ---------------------------------------------------------
        List<StickmanClip> loadedClips = [];
        if (jsonMap.containsKey('clips')) {
          loadedClips = (jsonMap['clips'] as List)
              .map((c) => StickmanClip.fromJson(c))
              .toList();
        } else if (jsonMap.containsKey('keyframes')) {
           loadedClips = [StickmanClip.fromJson(jsonMap)];
        }

        for (var clip in loadedClips) {
          // Normalize names: "sword idle.fbx" -> "sword idle"
          String cleanName = clip.name.replaceAll('.fbx', '');
          _clips[cleanName] = clip;
        }
        debugPrint("✅ LOADED ANIMATIONS: ${_clips.keys.join(', ')}");
      }

      _isLoaded = true;

      // Play pending animation if one was requested during load
      if (_pendingAnimation != null) {
        playAnimation(_pendingAnimation!);
        _pendingAnimation = null;
      }

      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("❌ CRITICAL ERROR loading animations: $e");
    }
  }

  void playAnimation(String name) {
    if (!_isLoaded) {
      _pendingAnimation = name;
      return;
    }

    if (_clips.containsKey(name)) {
      final clip = _clips[name];
      if (controller.activeClip != clip) {
        controller.activeClip = clip;
        controller.isPlaying = true;
        controller.currentFrameIndex = 0;
        controller.setMode(EditorMode.animate);
      }
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
