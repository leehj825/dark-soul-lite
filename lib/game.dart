import 'dart:math';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickman_3d/stickman_3d.dart';
import 'stickman_animator.dart';
import 'perspective_grid.dart';

enum PlayerState {
  idle,
  running,
  rolling,
  attacking,
  blocking
}

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

    // FIX: Use visibleGameSize for fullscreen retro look
    camera.viewfinder.visibleGameSize = Vector2(320, 180);
    camera.viewfinder.anchor = const Anchor(0.5, 0.8);

    // Debug mode
    debugMode = true;

    // Setup Camera Component (Logic)
    cameraComponent = SoulsCameraComponent();
    add(cameraComponent);

    // Add Floor
    world.add(PerspectiveGrid(cameraComponent));

    // Initialize Player
    final playerController = StickmanController();
    player = Player(controller: playerController);
    player.add(RectangleComponent(size: Vector2(50, 100), paint: BasicPalette.green.withAlpha(100).paint()));
    world.add(player);

    // Debug HUD
    camera.viewport.add(TextComponent(text: 'HUD WORKING', position: Vector2(20, 20)));

    // Initialize Boss
    final bossController = StickmanController();
    boss = Boss(controller: bossController);
    boss.position = Vector2(200, -200);
    world.add(boss);

    // UI Components (Joystick/Buttons) go directly to the game (HUD), not the world
    final knobPaint = BasicPalette.blue.paint()..color = BasicPalette.blue.color.withAlpha(200);
    final backgroundPaint = BasicPalette.blue.paint()..color = BasicPalette.blue.color.withAlpha(100);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
      priority: 10,
    );
    add(joystick);

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
  }

  @override
  void update(double dt) {
    // 1. Process input (this will set velocity if joystick is moving)
    if (!joystick.delta.isZero()) {
      // If we are rolling or attacking, ignore input (lock movement)
      if (player.state != PlayerState.rolling && player.state != PlayerState.attacking && player.state != PlayerState.blocking) {
         player.move(joystick.relativeDelta, cameraComponent.yaw, dt);
         player.switchState(PlayerState.running);
      }
    } else {
      // Joystick released
      if (player.state == PlayerState.running) {
        player.animator.velocity = Vector2.zero();
        player.switchState(PlayerState.idle);
      }
    }

    // 3. Update children (uses the velocity set above)
    super.update(dt);
  }
}

class Player extends PositionComponent {
  final StickmanAnimator animator;
  final double speed = 100.0;
  PlayerState state = PlayerState.idle;

  Player({required StickmanController controller})
      : animator = StickmanAnimator(controller: controller, size: Vector2(50, 100)),
        super(size: Vector2(50, 100), anchor: Anchor.center) {
    add(animator);
  }

  void switchState(PlayerState newState) {
    if (state == newState) return;
    state = newState;

    String animName;
    switch (state) {
      case PlayerState.idle:
        animName = "sword and shield idle";
        break;
      case PlayerState.running:
        animName = "sword and shield run";
        break;
      case PlayerState.rolling:
        animName = "Sprinting Forward Roll";
        break;
      case PlayerState.attacking:
        animName = "sword and shield slash";
        break;
      case PlayerState.blocking:
        animName = "sword and shield block idle";
        break;
    }
    animator.playAnimation(animName);
  }

  void move(Vector2 direction, double cameraYaw, double dt) {
    // Calculate world angle
    double joystickAngle = direction.screenAngle();
    double targetWorldAngle = cameraYaw + joystickAngle;

    Vector2 velocity = Vector2(sin(targetWorldAngle), -cos(targetWorldAngle)) * speed;

    position.add(velocity * dt);

    animator.velocity = velocity;
    animator.cameraYaw = cameraYaw;
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  void dodge() {
    if (state == PlayerState.rolling) return;

    switchState(PlayerState.rolling);

    // Lock movement for 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state == PlayerState.rolling) {
        switchState(PlayerState.idle);
      }
    });
  }
}

class Boss extends PositionComponent with HasGameRef<SoulsStickmanGame> {
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

    final player = gameRef.player;

    if (state == 'idle') {
       Vector2 diff = player.position - position;
       double targetAngle = atan2(diff.x, -diff.y);

       animator.facingAngleOverride = targetAngle;

       if (timer > 2.0) {
         state = 'attacking';
         timer = 0;
         animator.controller.isAttacking = true;
         animator.playAnimation("sword and shield slash");
       }
    } else if (state == 'attacking') {
      if (timer > 1.5) {
         state = 'idle';
         timer = 0;
         animator.playAnimation("sword and shield idle");
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
