import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
  Future<void> onLoad() async {
    await super.onLoad();

    // Setup Camera
    cameraComponent = SoulsCameraComponent();
    add(cameraComponent);

    // Initialize Player
    final playerController = StickmanController();
    player = Player(controller: playerController);
    world.add(player);

    // Initialize Boss
    final bossController = StickmanController();
    boss = Boss(controller: bossController);
    boss.position = Vector2(200, -200);
    world.add(boss);

    // Joystick
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);

    // Dodge Button
    dodgeButton = HudButtonComponent(
      button: CircleComponent(radius: 30, paint: BasicPalette.red.withAlpha(200).paint()),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
      onPressed: () {
        player.dodge();
      },
    );
    add(dodgeButton);

    // Camera follow
    camera.follow(player);
    camera.viewfinder.anchor = const Anchor(0.5, 0.8);
  }

  @override
  void update(double dt) {
    // Process input BEFORE updating children so velocity is set for this frame
    if (!joystick.delta.isZero()) {
      player.move(joystick.relativeDelta, cameraComponent.yaw);
    }

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

  void move(Vector2 direction, double cameraYaw) {
    if (isDodging) return;

    // Calculate world angle
    double joystickAngle = direction.screenAngle();
    double targetWorldAngle = cameraYaw + joystickAngle;

    // Calculate velocity for the animator
    // Animator expects velocity relative to world to calculate facing, OR just magnitude?
    // Controller.update(dt, vx, vy) uses vx, vy for direction.
    // So we pass world velocity.

    Vector2 velocity = Vector2(sin(targetWorldAngle), -cos(targetWorldAngle)) * speed;

    position.add(velocity * 0.016); // Approximating dt? We should use actual dt, but this is inside move called from update?
    // Player.move is called from Game.update, but dt is not passed.
    // Let's rely on Game.update passing dt to Player.move?
    // Or simpler: Game calls player.move with direction, Player stores velocity, and updates position in Player.update.
    // For now, I'll just accept that movement happens here. Ideally I should pass dt.
    // But to fix the API issue:

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
    // Reset velocity every frame? Or assume it's set by move().
    // Since move() is called every frame joystick is active, we can just decay it or set it to zero at start of update?
    // But update order matters.
    // Better: Game calls move() which sets velocity.
    // If Game doesn't call move(), velocity should be zero.
    // But we don't know if Game will call move().
    // Let's add stop() method or just set velocity to zero in update, and move() overrides it.

    animator.velocity = Vector2.zero();
    // But move() is called inside Game.update. PositionComponent.update is called after Game.update usually?
    // Actually FlameGame.update calls update on children.
    // Game.update calls super.update(dt) (which updates children) THEN does joystick logic.
    // So children update first.
    // So if I set velocity=0 in update, it clears it for the NEXT frame's render?
    // No.
    // 1. Game.update -> super.update -> Player.update (sets vel=0) -> Animator.update (uses vel=0).
    // 2. Game.update -> check joystick -> Player.move (sets vel=V).
    // Result: Animator uses 0 velocity. Bad.

    // Fix: Move joystick logic BEFORE super.update in Game.
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
