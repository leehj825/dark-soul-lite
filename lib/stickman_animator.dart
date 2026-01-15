import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:stickman_3d/stickman_3d.dart';
import 'custom_stickman_painter.dart';

class StickmanAnimator extends PositionComponent {
  final StickmanController controller;
  double cameraYaw = 0.0;
  double targetFacingAngle = 0.0;

  StickmanAnimator({
    required this.controller,
    super.size,
  });

  @override
  void render(Canvas canvas) {
    // Implement render(...) that passes cameraYaw to the painter.
    // Since we are in a Flame Component, we can use the CustomPainter to draw on the canvas.

    // We can't just instantiate CustomPainter and call paint because CustomPainter expects to be used in a CustomPaint widget.
    // However, we can manually invoke it.

    final painter = CustomStickmanPainter(
      controller: controller,
      cameraYaw: cameraYaw,
    );

    painter.paint(canvas, size.toSize());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Implement update(...) to handle manual rotation smoothing towards movement direction.
    // "controller.facingAngle" seems to be what we need to update.

    // Smooth rotation logic
    double currentAngle = controller.facingAngle;
    double diff = targetFacingAngle - currentAngle;

    // Normalize diff to -pi to pi
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;

    if (diff.abs() > 0.01) {
      double rotationSpeed = 5.0; // Radians per second
      double change = rotationSpeed * dt;
      if (change > diff.abs()) {
        controller.facingAngle = targetFacingAngle;
      } else {
        controller.facingAngle += change * diff.sign;
      }
    }

    // Also need to update the controller's internal animation state if needed
    controller.update(dt);
  }
}
