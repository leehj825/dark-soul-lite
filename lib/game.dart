import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickman_3d/stickman_3d.dart';
import 'stickman_animator.dart';

class SoulsStickmanGame extends FlameGame with HasKeyboardHandlerComponents {
  late Player player;
  late Boss boss;
  late SoulsCameraComponent cameraComponent;

  late final JoystickComponent joystick;
  late final HudButtonComponent dodgeButton;

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Enable debug mode to see component boundaries
    debugMode = true;

    // Setup Camera
    cameraComponent = SoulsCameraComponent();
    add(cameraComponent);

    // Initialize Player
    final playerController = StickmanController();
    player = Player(controller: playerController);
    // Add debug visual to player
    player.add(RectangleComponent(size: Vector2(50, 100), paint: BasicPalette.green.withAlpha(100).paint()));
    world.add(player);

    // Debug HUD Text
    camera.viewport.add(TextComponent(text: 'HUD WORKING', position: Vector2(100, 100)));

    // Initialize Boss
    final bossController = StickmanController();
    boss = Boss(controller: bossController);
    boss.position = Vector2(200, -200);
    world.add(boss);

    // Joystick
    final knobPaint = BasicPalette.blue.paint()..color = BasicPalette.blue.color.withAlpha(200);
    final backgroundPaint = BasicPalette.blue.paint()..color = BasicPalette.blue.color.withAlpha(100);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
      priority: 10,
    );
    add(joystick);

    // Dodge Button
    final dodgePaint = BasicPalette.red.paint()..color = BasicPalette.red.color.withAlpha(200);
    dodgeButton = HudButtonComponent(
      button: CircleComponent(radius: 30, paint: dodgePaint),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
      onPressed: () {
        player.dodge();
      },
      priority: 10,
    );
    add(dodgeButton);

    // Camera follow
    camera.follow(player);
    camera.viewfinder.anchor = const Anchor(0.5, 0.8);
  }

  @override
  void update(double dt) {
    // 1. Reset velocity to zero by default so player stops if no input
    player.animator.velocity = Vector2.zero();

    // 2. Process input (this will set velocity if joystick is moving)
    if (!joystick.delta.isZero()) {
      player.move(joystick.relativeDelta, cameraComponent.yaw, dt);
    }

    // 3. Update children (uses the velocity set above)
    super.update(dt);
  }
}

class Player extends PositionComponent {
  final StickmanAnimator animator;
  final double speed = 100.0;
  bool isDodging = false;

  Player({required StickmanController controller})
      : animator = StickmanAnimator(controller: controller, size: Vector2(50, 100)),
        super(size: Vector2(50, 100), anchor: Anchor.center) {
    add(animator);
  }

  void move(Vector2 direction, double cameraYaw, double dt) {
    if (isDodging) return;

    // Calculate world angle
    double joystickAngle = direction.screenAngle();
    double targetWorldAngle = cameraYaw + joystickAngle;

    // Calculate velocity for the animator
    // Animator expects velocity relative to world to calculate facing, OR just magnitude?
    // Controller.update(dt, vx, vy) uses vx, vy for direction.
    // So we pass world velocity.

    Vector2 velocity = Vector2(sin(targetWorldAngle), -cos(targetWorldAngle)) * speed;

    position.add(velocity * dt);

    animator.velocity = velocity;
    animator.cameraYaw = cameraYaw;
    // We do NOT set animator.targetFacingAngle anymore, because controller derives it from velocity.
  }

  // Need to zero out velocity if no input?
  // Game calls move() only if joystick is not zero.
  // So we need an update loop here to reset velocity if not moving.

  @override
  void update(double dt) {
    super.update(dt);
  }

  void dodge() {
    if (isDodging) return;
    isDodging = true;

    // Dash: High velocity?
    // StickmanController doesn't have 'dash'.
    // Maybe just high speed.
    // And set state to avoid input interruption.

    // We can't use playAnimation('dash').
    // We will just assume visual effect or speed boost.

    Future.delayed(const Duration(milliseconds: 500), () {
      isDodging = false;
    });
  }
}

class Boss extends PositionComponent {
  final StickmanAnimator animator;

  Boss({required StickmanController controller})
      : animator = StickmanAnimator(controller: controller, size: Vector2(50, 100)),
        super(size: Vector2(50, 100), anchor: Anchor.center) {
    add(animator);
    scale = Vector2.all(4.0);
  }

  double timer = 0;
  String state = 'idle';

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;

    final player = (parent as SoulsStickmanGame).player;

    if (state == 'idle') {
       Vector2 diff = player.position - position;
       double targetAngle = atan2(diff.x, -diff.y);

       // Boss rotates in place.
       // Animator.velocity is 0.
       // We use facingAngleOverride.
       animator.facingAngleOverride = targetAngle;

       if (timer > 2.0) {
         state = 'attacking';
         timer = 0;
         animator.controller.isAttacking = true;
       }
    } else if (state == 'attacking') {
      // Attack duration handling
      if (!animator.controller.isAttacking) {
        // Controller resets isAttacking automatically after animation?
        // Logic: _attackTimer > 0.3.
        // So we just wait.
        if (timer > 1.5) {
           state = 'idle';
           timer = 0;
        }
      }
    }
  }
}

class SoulsCameraComponent extends Component {
  double yaw = 0.0;

  @override
  void update(double dt) {
  }
}
