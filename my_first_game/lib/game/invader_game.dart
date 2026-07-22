import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:my_first_game/game/collision.dart';
import 'package:my_first_game/game/components/boss_component.dart';
import 'package:my_first_game/game/components/bullet_component.dart';
import 'package:my_first_game/game/components/enemy_component.dart';
import 'package:my_first_game/game/components/particle_component.dart';
import 'package:my_first_game/game/components/player_component.dart';
import 'package:my_first_game/game/components/starfield_component.dart';
import 'package:my_first_game/game/models/enemy_type.dart';
import 'package:my_first_game/game/wave_generator.dart';
import 'package:my_first_game/state/game_session.dart';

/// The main Flame game loop for the space-invader style game.
///
/// Wires together the wave generator, collision detection, player/enemy/boss
/// components, and drag/tap input into a single playable game surface. All
/// HUD state (score/lives/wave/boss) is pushed to [GameSession].
class InvaderGame extends FlameGame with DragCallbacks, TapCallbacks {
  InvaderGame({required this.session});

  final GameSession session;

  static const double canvasWidth = WaveGenerator.canvasWidth;
  static const double canvasHeight = 670;

  final math.Random _random = math.Random();

  PlayerComponent? player;
  BossComponent? boss;
  double lastShotMs = 0;
  double invulnerableUntilMs = 0;
  bool pointerActive = false;

  double enemyDirection = 1;
  double enemySpeed = 0;
  double enemyShotAtMs = 0;
  bool _gameOverTriggered = false;
  bool _stopped = false;

  /// Marks this game instance as stopped so any in-flight delayed callbacks
  /// (wave-transition timers) become no-ops instead of mutating a
  /// [GameSession]/board that has moved on to a different run.
  void stop() {
    _stopped = true;
  }

  List<EnemyComponent> get liveEnemies =>
      children.whereType<EnemyComponent>().where((e) => e.alive).toList();

  @override
  Color backgroundColor() => const Color(0xFF05060F);

  @override
  Future<void> onLoad() async {
    await add(StarfieldComponent(size: Vector2(canvasWidth, canvasHeight)));
    final newPlayer = PlayerComponent()
      ..position = Vector2(canvasWidth / 2 - 18, canvasHeight - 46);
    player = newPlayer;
    await add(newPlayer);
    spawnWave(session.wave);
  }

  /// Clears any existing enemies/boss and spawns the next wave (or boss)
  /// according to [WaveGenerator].
  void spawnWave(int wave) {
    _gameOverTriggered = false;

    for (final enemy in children.whereType<EnemyComponent>().toList()) {
      enemy.removeFromParent();
    }
    boss?.removeFromParent();
    boss = null;

    if (WaveGenerator.isBossWave(wave)) {
      final hp = WaveGenerator.bossHpForWave(wave);
      final newBoss = BossComponent(hp: hp, maxHp: hp)
        ..position = Vector2((canvasWidth - 64) / 2, 70)
        ..shootAtMs = currentTime() * 1000;
      boss = newBoss;
      add(newBoss);
      session.updateHud(bossActive: true, bossHp: hp, bossMaxHp: hp, wave: wave);
      return;
    }

    enemyDirection = 1;
    enemySpeed = WaveGenerator.enemySpeedForWave(wave);
    enemyShotAtMs = currentTime() * 1000;
    for (final spec in WaveGenerator.enemiesForWave(wave)) {
      add(EnemyComponent(spec: spec));
    }
    session.updateHud(bossActive: false, wave: wave);
  }

  /// Removes [enemy], awards its points, spawns hit particles, and triggers
  /// the next wave once the current wave has been fully cleared.
  void registerHit(EnemyComponent enemy) {
    if (!enemy.alive) return;
    enemy.alive = false;
    enemy.removeFromParent();
    session.updateHud(score: session.score + enemy.points);
    _spawnParticles(enemy.position, enemy.type.color, 10);
    if (liveEnemies.isEmpty) {
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (_stopped) return;
        spawnWave(session.wave + 1);
      });
    }
  }

  /// Applies one hit of damage to the active boss, awarding a bonus and
  /// advancing the wave once the boss is defeated.
  void registerBossHit() {
    final activeBoss = boss;
    if (activeBoss == null) return;
    activeBoss.hp -= 1;
    session.updateHud(bossHp: activeBoss.hp);
    if (activeBoss.hp <= 0) {
      _spawnParticles(activeBoss.position, const Color(0xFFB026FF), 40);
      session.updateHud(score: session.score + 500, bossActive: false);
      activeBoss.removeFromParent();
      boss = null;
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (_stopped) return;
        spawnWave(session.wave + 1);
      });
    }
  }

  /// Applies a hit to the player, respecting a brief invulnerability window,
  /// and ends the game once lives reach zero.
  void registerPlayerHit() {
    final nowMs = currentTime() * 1000;
    if (nowMs < invulnerableUntilMs) return;
    invulnerableUntilMs = nowMs + 1400;
    session.updateHud(lives: session.lives - 1);
    session.triggerHitFlash();
    if (session.lives <= 0) {
      session.endGame(finalScore: session.score, finalWave: session.wave);
    }
  }

  void _spawnParticles(Vector2 origin, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final velocity = Vector2(
        (_random.nextDouble() - 0.5) * 6,
        (_random.nextDouble() - 0.5) * 6,
      );
      add(ParticleComponent(
        position: origin.clone(),
        velocity: velocity,
        color: color,
        life: 26,
      ));
    }
  }

  void _tryShoot() {
    final nowMs = currentTime() * 1000;
    if (!canShoot(nowMs: nowMs, lastShotMs: lastShotMs)) return;
    lastShotMs = nowMs;
    final p = player;
    if (p == null) return;
    add(BulletComponent(
      position: Vector2(p.position.x + p.size.x / 2 - 1.5, p.position.y - 8),
      velocityY: -9,
      canvasHeight: canvasHeight,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (pointerActive) _tryShoot();
    if (boss == null) {
      _advanceEnemyFormation(dt);
    } else {
      _advanceBoss(dt);
    }
    _resolveCollisions();
  }

  /// Marches the enemy formation side to side, drops it down and speeds it
  /// up on each edge bounce, fires enemy bullets at an increasing cadence,
  /// and ends the game if the formation reaches the player's row.
  void _advanceEnemyFormation(double dt) {
    final enemies = liveEnemies;
    if (enemies.isEmpty) return;

    var hitEdge = false;
    for (final enemy in enemies) {
      enemy.position.x += enemySpeed * enemyDirection * dt * 60;
      if (enemy.position.x < 8 || enemy.position.x + enemy.size.x > canvasWidth - 8) {
        hitEdge = true;
      }
    }

    if (hitEdge) {
      enemyDirection *= -1;
      for (final enemy in enemies) {
        enemy.position.y += 18;
      }
      enemySpeed += 0.05;
    }

    final nowMs = currentTime() * 1000;
    final shotInterval = math.max(
      280,
      900 - session.wave * 12 - (24 - enemies.length) * 10,
    );
    if (nowMs - enemyShotAtMs > shotInterval) {
      enemyShotAtMs = nowMs;
      final shooter = enemies[_random.nextInt(enemies.length)];
      add(BulletComponent(
        position: Vector2(
          shooter.position.x + shooter.size.x / 2,
          shooter.position.y + shooter.size.y,
        ),
        velocityY: 4 + session.wave * 0.08,
        canvasHeight: canvasHeight,
        isEnemy: true,
      ));
    }

    final lowestY = enemies.map((e) => e.position.y + e.size.y).reduce(math.max);
    if (lowestY >= (player?.position.y ?? canvasHeight) - 14 && !_gameOverTriggered) {
      _gameOverTriggered = true;
      session.endGame(finalScore: session.score, finalWave: session.wave);
      return;
    }
  }

  /// Moves the boss side to side, bouncing off the canvas edges, and fires a
  /// three-bullet spread at an increasing cadence.
  void _advanceBoss(double dt) {
    final activeBoss = boss!;
    activeBoss.position.x += activeBoss.vx * activeBoss.dir * dt * 60;
    if (activeBoss.position.x < 16 ||
        activeBoss.position.x > canvasWidth - 16 - activeBoss.size.x) {
      activeBoss.dir *= -1;
    }

    final nowMs = currentTime() * 1000;
    final shotInterval = math.max(500, 1100 - session.wave * 10);
    if (nowMs - activeBoss.shootAtMs > shotInterval) {
      activeBoss.shootAtMs = nowMs;
      final centerX = activeBoss.position.x + activeBoss.size.x / 2;
      final bottomY = activeBoss.position.y + activeBoss.size.y;
      for (final offsetX in [0.0, -16.0, 16.0]) {
        add(BulletComponent(
          position: Vector2(centerX + offsetX, bottomY),
          velocityY: 4.5,
          canvasHeight: canvasHeight,
          isEnemy: true,
        ));
      }
    }
  }

  void _resolveCollisions() {
    final bullets = children.whereType<BulletComponent>().where((b) => !b.isEnemy).toList();
    for (final bullet in bullets) {
      final activeBoss = boss;
      if (activeBoss != null) {
        if (aabbIntersects(
          ax: bullet.position.x,
          ay: bullet.position.y,
          aw: bullet.size.x,
          ah: bullet.size.y,
          bx: activeBoss.position.x,
          by: activeBoss.position.y,
          bw: activeBoss.size.x,
          bh: activeBoss.size.y,
        )) {
          bullet.removeFromParent();
          registerBossHit();
          continue;
        }
      }
      for (final enemy in liveEnemies) {
        if (aabbIntersects(
          ax: bullet.position.x,
          ay: bullet.position.y,
          aw: bullet.size.x,
          ah: bullet.size.y,
          bx: enemy.position.x,
          by: enemy.position.y,
          bw: enemy.size.x,
          bh: enemy.size.y,
        )) {
          bullet.removeFromParent();
          registerHit(enemy);
          break;
        }
      }
    }

    final enemyBullets = children.whereType<BulletComponent>().where((b) => b.isEnemy).toList();
    final p = player;
    if (p == null) return;
    for (final bullet in enemyBullets) {
      if (aabbIntersects(
        ax: bullet.position.x,
        ay: bullet.position.y,
        aw: bullet.size.x,
        ah: bullet.size.y,
        bx: p.position.x,
        by: p.position.y,
        bw: p.size.x,
        bh: p.size.y,
      )) {
        bullet.removeFromParent();
        registerPlayerHit();
      }
    }
  }

  void _movePlayerTo(double globalX) {
    final p = player;
    if (p == null) return;
    p.moveTo(globalX, canvasWidth);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    pointerActive = true;
    _movePlayerTo(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _movePlayerTo(event.localStartPosition.x + event.localDelta.x);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    pointerActive = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    pointerActive = true;
    _movePlayerTo(event.localPosition.x);
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    pointerActive = false;
  }
}
