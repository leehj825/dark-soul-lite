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
  void render(Canvas canvas) {
    // Determine the view rotation Y (Yaw)
    // viewRotationY determines the camera angle relative to the stickman.
    // effectiveYaw = StickmanFacing - CameraYaw

    // If controller is moving, it updates its internal facing angle.
    // If not moving (Boss), it stays static (0).
    // The StickmanPainter uses 'viewRotationY' to rotate the model during projection.

    // Logic:
    // If override is present, use it.
    // If not, rely on controller's internal state (which we can't easily read perfectly if private, but we assume it matches velocity).
    // Actually, controller.facingAngle IS a getter. I saw `double get facingAngle => _facingAngle;`.
    // So we CAN read it.

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
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update the controller with velocity
    // This drives the procedural animation (running, facing)
    controller.update(dt, velocity.x, velocity.y);
  }
}
