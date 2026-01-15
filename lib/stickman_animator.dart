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
      // 1. Load the file content
      final sapContent = await rootBundle.loadString('assets/data/animations.sap');

      // 2. Use StickmanPersistence to parse the WHOLE project (Skeleton + Clips)
      // This ensures your custom stickman design is loaded, not just the default one.
      final library = StickmanPersistence.load(sapContent);

      // 3. Apply the library to the controller
      // (This updates the skeleton structure and registers all clips)
      controller.loadLibrary(library);

      _isLoaded = true;
      debugPrint("Stickman Library Loaded: ${library.clips.length} clips found.");

      // Force initial update to apply the skeleton pose
      controller.update(0.0, 0.0, 0.0);
    } catch (e) {
      debugPrint("Error initializing StickmanController: $e");
    }
  }

  void playAnimation(String name) {
    if (!_isLoaded || controller.library == null) return;

    try {
      // Look up the clip in the library loaded into the controller
      if (controller.library!.clips.containsKey(name)) {
        final clip = controller.library!.clips[name];
        controller.activeClip = clip;
        controller.isPlaying = true;
        controller.currentFrameIndex = 0;
        controller.setMode(EditorMode.animate);
      } else {
        debugPrint("Animation '$name' not found. Available: ${controller.library!.clips.keys.join(', ')}");
      }
    } catch(e) {
      debugPrint("Animation playback error: $e");
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;

    // Debug circle
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
      debugPrint('StickmanPainter error: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isLoaded) return;

    try {
      // Update the controller with velocity
      controller.update(dt, velocity.x, velocity.y);
    } catch (e) {
      debugPrint("Error updating StickmanController: $e");
    }
  }
}
