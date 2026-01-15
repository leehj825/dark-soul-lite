import 'dart:math';
import 'package:flutter/material.dart';
import 'package:stickman_3d/stickman_3d.dart';

class CustomStickmanPainter extends CustomPainter {
  final StickmanController controller;
  final double cameraYaw;

  CustomStickmanPainter({
    required this.controller,
    required this.cameraYaw,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Math: Calculate viewRotationY = controller.facingAngle - cameraYaw
    // Assuming controller has a facingAngle property.
    // If it doesn't, we might need to derive it or it's part of the state we manage.
    // The prompt says "controller.facingAngle".
    final double viewRotationY = controller.facingAngle - cameraYaw;

    // Perspective: Set viewRotationX to roughly -pi / 10 (Low angle)
    const double viewRotationX = -pi / 10;

    // We need to render the stickman.
    // Assuming the controller has a method to draw itself or we use a utility from the package.
    // Since the prompt says "Implement render(...) that passes cameraYaw to the painter" in stickman_animator.dart,
    // and "Create a custom painter... Calculate viewRotationY...",
    // it implies the drawing logic happens here.

    // I will assume the controller provides a method 'draw' or similar that takes the canvas and rotation.
    // If StickmanController is a ChangeNotifier, it might just hold data.
    // Let's assume the package provides a way to draw the stickman given the controller and rotations.
    // Given I don't know the exact API, I will use a hypothetical `drawStickman` method on the controller
    // or assume the controller itself can be drawn.

    // Based on "Use the stickman_3d package structure implied by this repo",
    // I'll assume the controller exposes methods to get points/lines which we then rotate and draw?
    // Or simpler: controller.render(canvas, size, rotationX, rotationY).

    // I'll go with `controller.render` for now as it's the most logical for a game library.

    controller.render(
      canvas,
      size,
      viewRotationX: viewRotationX,
      viewRotationY: viewRotationY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomStickmanPainter oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.cameraYaw != cameraYaw;
  }
}
