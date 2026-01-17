import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game.dart'; // Import to access SoulsCameraComponent

class PerspectiveGrid extends PositionComponent {
  final SoulsCameraComponent cameraComponent;
  final Paint _gridPaint = Paint()
    ..color = const Color(0xFF444444) // Dark gray grid lines
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  PerspectiveGrid(this.cameraComponent) : super(priority: -100); // Render behind everything

  @override
  void render(Canvas canvas) {
    // 1. Get the camera rotation (Yaw) from your existing camera component
    final double yaw = -cameraComponent.yaw; // Invert for floor rotation

    // 2. Define the "3D" tilt (Pitch) - must match StickmanAnimator's logic
    // StickmanAnimator uses -pi / 10 (~-18 degrees)
    const double pitch = -pi / 10;

    // Grid settings
    const double spacing = 50.0;
    const int gridSize = 20; // How many lines to draw

    // Center the rendering on screen
    canvas.save();

    // 3. Projection Logic (3D Point -> 2D Screen)
    Offset project(double x, double z) {
      // Rotate around Y axis (Yaw)
      double rx = x * cos(yaw) - z * sin(yaw);
      double rz = x * sin(yaw) + z * cos(yaw);

      // Apply Pitch (Tilt the world)
      // Flatten Z into Y based on pitch
      double screenX = rx;
      double screenY = rz * sin(pitch);

      return Offset(screenX, screenY);
    }

    // 4. Draw vertical lines (Z-axis)
    for (int i = -gridSize; i <= gridSize; i++) {
      double x = i * spacing;
      Offset start = project(x, -gridSize * spacing);
      Offset end = project(x, gridSize * spacing);
      canvas.drawLine(start, end, _gridPaint);
    }

    // 5. Draw horizontal lines (X-axis)
    for (int i = -gridSize; i <= gridSize; i++) {
      double z = i * spacing;
      Offset start = project(-gridSize * spacing, z);
      Offset end = project(gridSize * spacing, z);
      canvas.drawLine(start, end, _gridPaint);
    }

    canvas.restore();
  }
}
