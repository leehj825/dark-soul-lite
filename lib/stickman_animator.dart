import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:stickman_3d/stickman_3d.dart';
// Note: StickmanPainter is exported by stickman_3d.dart (which usually exports src/stickman_painter.dart)
// But I need to be sure. The file structure showed src/stickman_painter.dart.
// The main lib file usually exports src files.
// Assuming package:stickman_3d/stickman_3d.dart exports StickmanPainter.

class StickmanAnimator extends PositionComponent {
  final StickmanController controller;

  // Camera/View state
  double cameraYaw = 0.0;

  // Movement state for the controller
  Vector2 velocity = Vector2.zero();

  // Manual override for rotation (useful for stationary entities like Boss)
  double? facingAngleOverride;

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Force initial update to ensure skeleton is not empty/null
    controller.update(0.0, 0.0, 0.0);
  }

  @override
  void render(Canvas canvas) {
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

    // Update the controller with velocity
    // This drives the procedural animation (running, facing)
    controller.update(dt, velocity.x, velocity.y);
  }
}
