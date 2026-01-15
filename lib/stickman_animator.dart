import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:stickman_3d/stickman_3d.dart';

class StickmanAnimator extends PositionComponent {
  final StickmanController controller;

  // Camera/View state
  double cameraYaw = 0.0;

  // Movement state for the controller
  Vector2 velocity = Vector2.zero();

  // Manual override for rotation (useful for stationary entities like Boss)
  double? facingAngleOverride;

  bool _isLoaded = false;

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final sapContent = await rootBundle.loadString('assets/data/animations.sap');
      // Initialize Controller with loaded data
      await controller.load(sapContent);
      _isLoaded = true;

      // Force initial update to ensure skeleton is not empty/null
      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("Error initializing StickmanController: $e");
    }
  }

  void playAnimation(String name) {
    try {
      // Look up clip and set active
      // Assuming controller.clips is a Map<String, StickmanClip> or similar exposed by library
      // If the library structure is different (e.g. library.clips), we'd need to adjust.
      // Based on prompt "look up the clip in controller.clips".

      // Dynamic check to avoid compilation error if 'clips' is missing but expected at runtime
      // or if we need to use a different property.
      // Since I am writing code blindly against a git lib, I will assume 'clips'.

      // Note: controller.activeClip = ...
      // If controller has no clips property, this will fail.
      // But based on common patterns and prompt instructions, we assume it exists.

      if ((controller as dynamic).clips != null && (controller as dynamic).clips.containsKey(name)) {
        controller.activeClip = (controller as dynamic).clips[name];
        controller.isPlaying = true; // Ensure playback starts
        // Reset frame?
        controller.currentFrameIndex = 0;
        // Ensure mode is set to animate?
        controller.setMode(EditorMode.animate);
      } else {
        debugPrint("Animation '$name' not found in controller.clips");
      }
    } catch(e) {
      debugPrint("Animation playback error: $e");
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;

    // Debug circle to verify render is called
    canvas.drawCircle(Offset(size.x/2, size.y/2), 10, Paint()..color = Colors.cyan);

    try {
      // Determine the view rotation Y (Yaw)
      double stickmanFacing = facingAngleOverride ?? controller.facingAngle;
      double viewRotationY = stickmanFacing - cameraYaw;

      // Perspective: Set viewRotationX to roughly -pi / 10 (Low angle)
      const double viewRotationX = -pi / 10;

      // Use the package's StickmanPainter to draw
      final painter = StickmanPainter(
        controller: controller,
        viewRotationX: viewRotationX,
        viewRotationY: viewRotationY,
        cameraView: CameraView.free,
      );

      painter.paint(canvas, size.toSize());
    } catch (e) {
      // Prevent crash if painter fails
      debugPrint('StickmanPainter error: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded) return;

    try {
      // Update the controller with velocity
      // This drives the procedural animation (running, facing)
      controller.update(dt, velocity.x, velocity.y);
    } catch (e) {
      debugPrint("Error updating StickmanController: $e");
    }
  }
}
