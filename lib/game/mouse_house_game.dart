import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/cat_component.dart';
import 'models/cat_state.dart';
import 'models/game_state.dart';
import 'models/power_up.dart';
import 'rendering/code_game_components.dart';
import 'rendering/code_maze_component.dart';
import 'rendering/forest_background_component.dart';
import 'rendering/procedural_obstacle_component.dart';
import 'services/level_generator.dart';
import 'services/level_repository.dart';
import 'services/progress_service.dart';
import 'systems/collision_system.dart';
import 'systems/detection_system.dart';
import 'systems/navigation_system.dart';
import 'systems/scoring_system.dart';

class MouseHouseGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  final int levelNumber;
  final VoidCallback onStateChanged;

  MouseHouseGame({
    required this.levelNumber,
    required this.onStateChanged,
  }) : super();

  late MazeLevelData levelData;
  late GameSessionState session;
  late CollisionSystem collisionSystem;
  late NavigationSystem navigationSystem;
  late DetectionSystem detectionSystem;

  /// Walls of this play-through (walls broken with the hammer become floor).
  late List<List<bool>> wallGrid;

  /// [wallGrid] plus crates: what movement, pathfinding and sight use.
  late List<List<bool>> walkGrid;

  late ForestBackgroundComponent backgroundComponent;
  late CodeMazeComponent mazeComponent;
  late CodeMouseComponent mouseComponent;
  late CodeHouseComponent houseComponent;
  final List<CodeCheeseComponent> cheeseComponents = [];
  final List<ProceduralObstacleComponent> obstacleComponents = [];
  final List<CodePowerUpComponent> powerUpComponents = [];
  final List<CatComponent> catComponents = [];

  final PositionComponent worldContainer = PositionComponent();
  late Vector2 mapPixelSize;

  // Active path and hint visualization
  final List<Vector2> hintPath = [];
  Vector2? targetTapMarker;
  double tapMarkerTimer = 0.0;
  double hintAnimProgress = 0.0;
  bool isHintActive = false;
  int _hintToken = 0;

  // "Life lost" banner shown by the HUD
  double caughtFlashTimer = 0.0;
  String lastLifeLostReason = '';

  // Short message toast for the HUD (power-up picked, wall broken...)
  String? toastMessage;
  double _toastTimer = 0.0;

  // Power-ups currently running -> seconds left
  final Map<PowerUpKind, double> activeEffects = {};

  // Wall breaker ("hammer")
  int hammerCharges = 0;
  bool breakMode = false;
  final List<_BreakDust> _dust = [];
  double _clock = 0.0;

  // Camera
  double userZoomFactor = 1.0;
  double _topInset = 135.0;
  double _bottomInset = 95.0;

  LevelDifficulty get difficulty => LevelGenerator.difficultyFor(levelNumber);

  /// Text for the intro card, e.g. "NEW: Freeze power-up".
  List<String> get introNotes {
    final notes = <String>[];
    for (final k in PowerUpKind.values) {
      if (k.introducedAt == levelNumber) notes.add('NEW: ${k.emoji} ${k.label} power-up. Grab the orb!');
    }
    if (levelNumber == 4) notes.add('NEW: Mouse traps. Your route avoids them, but watch out!');
    if (levelNumber == 5) notes.add('First MEDIUM level: 2 cats on patrol.');
    if (levelNumber == 6) notes.add('NEW: Crates. Hide behind them or smash them.');
    if (levelNumber == 10) notes.add('First HARD level: 3 cats and a bigger maze.');
    if (levelNumber == 1) notes.add('Tap a tile to move. Stay out of the cat\'s radar.');
    return notes;
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0D20);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    levelData = LevelRepository.getLevel(levelNumber);
    session = GameSessionState(
      maxHearts: 3,
      hearts: 3,
      totalCheese: levelData.cheesePositions.length,
      status: GameStatus.paused, // waits for the intro card
      remainingTime: levelData.timeLimitSeconds.toDouble(),
    );
    hammerCharges = levelData.hammerCharges;

    mapPixelSize = Vector2(levelData.mapWidth * levelData.tileSize, levelData.mapHeight * levelData.tileSize);

    // Own copies: the cached level data must stay untouched by broken walls.
    wallGrid = [for (final row in levelData.walkableGrid) [...row]];
    walkGrid = [for (final row in wallGrid) [...row]];
    for (final obs in levelData.obstacles) {
      if (obs.kind == ObstacleKind.crate || obs.kind == ObstacleKind.bush) {
        final g = _cellOf(obs.position);
        walkGrid[g.y][g.x] = false;
      }
    }

    collisionSystem = CollisionSystem(
      mapWidth: levelData.mapWidth,
      mapHeight: levelData.mapHeight,
      tileSize: levelData.tileSize,
      walkableGrid: walkGrid,
    );
    navigationSystem = NavigationSystem(
      mapWidth: levelData.mapWidth,
      mapHeight: levelData.mapHeight,
      tileSize: levelData.tileSize,
      walkableGrid: walkGrid,
    );
    detectionSystem = DetectionSystem(collisionSystem: collisionSystem);

    backgroundComponent = ForestBackgroundComponent(theme: levelData.theme);
    add(backgroundComponent);

    mazeComponent = CodeMazeComponent(
      mapWidth: levelData.mapWidth,
      mapHeight: levelData.mapHeight,
      tileSize: levelData.tileSize,
      walkableGrid: wallGrid,
      mouseSpawn: levelData.mouseSpawn,
      housePosition: levelData.housePosition,
      theme: levelData.theme,
    );
    worldContainer.add(mazeComponent);

    for (final obs in levelData.obstacles) {
      final comp = ProceduralObstacleComponent(
        kind: obs.kind,
        position: obs.position,
        size: Vector2.all(levelData.tileSize),
      );
      obstacleComponents.add(comp);
      worldContainer.add(comp);
    }

    for (int i = 0; i < levelData.cheesePositions.length; i++) {
      final cheese = CodeCheeseComponent(id: i, position: levelData.cheesePositions[i]);
      cheeseComponents.add(cheese);
      worldContainer.add(cheese);
    }

    for (final p in levelData.powerUps) {
      final comp = CodePowerUpComponent(kind: p.kind, position: p.position);
      powerUpComponents.add(comp);
      worldContainer.add(comp);
    }

    houseComponent = CodeHouseComponent(position: levelData.housePosition);
    worldContainer.add(houseComponent);

    for (final catCfg in levelData.cats) {
      final cat = CatComponent(config: catCfg, nav: navigationSystem, detection: detectionSystem);
      catComponents.add(cat);
      worldContainer.add(cat);
    }

    mouseComponent = CodeMouseComponent(spawnPosition: levelData.mouseSpawn);
    worldContainer.add(mouseComponent);

    add(worldContainer);
    _adjustGameScale();
    Future.delayed(Duration.zero, onStateChanged);
  }

  GridPoint _cellOf(Vector2 p) => GridPoint(
        (p.x / levelData.tileSize).floor().clamp(0, levelData.mapWidth - 1),
        (p.y / levelData.tileSize).floor().clamp(0, levelData.mapHeight - 1),
      );

  /// Called by the intro card.
  void startLevel() {
    if (session.status != GameStatus.paused) return;
    session.status = GameStatus.ready;
    onStateChanged();
  }

  // --------------------------------------------------------------------------
  // CAMERA
  // --------------------------------------------------------------------------
  /// Space (in logical pixels) taken by the HUD above and below the board.
  void setViewportInsets({required double top, required double bottom}) {
    if ((top - _topInset).abs() < 0.5 && (bottom - _bottomInset).abs() < 0.5) return;
    _topInset = top;
    _bottomInset = bottom;
    _adjustGameScale();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _adjustGameScale();
  }

  /// Fits the board between the HUD bars. Big maps are not shrunk below a
  /// playable tile size; instead the camera follows the mouse (zoom out to see
  /// the whole map). With [dt] the camera glides, otherwise it snaps.
  void _adjustGameScale({double? dt}) {
    if (!isLoaded) return;
    const margin = 14.0;
    final availW = size.x - margin * 2;
    final availH = math.max(100.0, size.y - (_topInset + _bottomInset));

    final fit = math.min(availW / mapPixelSize.x, availH / mapPixelSize.y);
    final play = math.max(fit, 0.78); // ~25px tiles on screen
    final scale = (play * userZoomFactor).clamp(fit, 2.5);

    double axis(double avail, double start, double mapLen, double focus) {
      final len = mapLen * scale;
      if (len <= avail) return start + (avail - len) / 2;
      final ideal = start + avail / 2 - focus * scale;
      return ideal.clamp(start + avail - len - 6, start + 6);
    }

    final focus = mouseComponent.position;
    final target = Vector2(
      axis(availW, margin, mapPixelSize.x, focus.x),
      axis(availH, _topInset, mapPixelSize.y, focus.y),
    );
    worldContainer.scale = Vector2.all(scale);
    if (dt == null) {
      worldContainer.position = target;
    } else {
      final k = (dt * 6).clamp(0.0, 1.0);
      worldContainer.position += (target - worldContainer.position) * k;
    }
  }

  void setZoom(double factor) {
    userZoomFactor = factor.clamp(0.4, 1.8);
    _adjustGameScale();
    onStateChanged();
  }

  void zoomIn() => setZoom(userZoomFactor + 0.2);
  void zoomOut() => setZoom(userZoomFactor - 0.2);
  void resetZoom() => setZoom(1.0);

  Vector2 _screenToWorld(Vector2 screenPosition) =>
      (screenPosition - worldContainer.position) / worldContainer.scale.x;

  // --------------------------------------------------------------------------
  // INPUT
  // --------------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (session.status != GameStatus.ready && session.status != GameStatus.moving) return;

    final worldPos = _screenToWorld(event.canvasPosition);
    if (worldPos.x < 0 || worldPos.y < 0 || worldPos.x >= mapPixelSize.x || worldPos.y >= mapPixelSize.y) {
      return; // Tapped outside the map
    }
    final gridPt = navigationSystem.worldToGrid(worldPos);

    if (breakMode) {
      _tryBreak(gridPt);
      return;
    }

    if (!navigationSystem.isGridWalkable(gridPt.x, gridPt.y)) {
      // Tapping a wall/crate is a handy shortcut into break mode.
      if (hammerCharges > 0) showToast('Tap 🔨 BREAK first to smash walls');
      return;
    }

    // Route around untriggered traps whenever another way exists.
    final traps = <GridPoint>{
      for (final o in obstacleComponents)
        if (o.kind == ObstacleKind.trap && !o.isTriggered) _cellOf(o.position),
    };
    final path = navigationSystem.findPath(mouseComponent.position, worldPos, avoid: traps);
    if (path.isNotEmpty) {
      session.status = GameStatus.moving;
      targetTapMarker = worldPos.clone();
      tapMarkerTimer = 1.0;
      mouseComponent.navigateToPath(path);
      onStateChanged();
    }
  }

  // --------------------------------------------------------------------------
  // WALL BREAKER
  // --------------------------------------------------------------------------
  void toggleBreakMode() {
    if (session.status != GameStatus.ready && session.status != GameStatus.moving) return;
    if (hammerCharges <= 0) {
      breakMode = false;
      showToast('No hammers left on this level');
      return;
    }
    breakMode = !breakMode;
    if (breakMode) showToast('Tap a wall or crate to smash it');
    onStateChanged();
  }

  void _tryBreak(GridPoint g) {
    final w = levelData.mapWidth, h = levelData.mapHeight;
    if (g.x <= 0 || g.y <= 0 || g.x >= w - 1 || g.y >= h - 1) {
      showToast('The outer wall is too strong!');
      return;
    }
    if (walkGrid[g.y][g.x]) {
      breakMode = false;
      showToast('Pick a wall or a crate');
      onStateChanged();
      return;
    }

    // Crate?
    ProceduralObstacleComponent? crate;
    for (final o in obstacleComponents) {
      if (o.kind != ObstacleKind.trap && o.isMounted && _cellOf(o.position) == g) crate = o;
    }
    if (crate != null) {
      crate.removeFromParent();
    } else {
      wallGrid[g.y][g.x] = true;
      mazeComponent.markDirty();
    }
    walkGrid[g.y][g.x] = true;
    hammerCharges--;
    breakMode = false;
    final centre = navigationSystem.gridToWorld(g);
    for (int i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      _dust.add(_BreakDust(centre.clone(), Vector2(math.cos(a), math.sin(a)) * (40 + i * 6.0)));
    }
    showToast(crate != null ? 'Crate smashed!' : 'Wall smashed! New path open');
    onStateChanged();
  }

  void showToast(String message) {
    toastMessage = message;
    _toastTimer = 2.2;
    onStateChanged();
  }

  // --------------------------------------------------------------------------
  // GAME LOOP
  // --------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    _adjustGameScale(dt: dt); // camera follows the mouse on big maps

    if (tapMarkerTimer > 0) {
      tapMarkerTimer -= dt;
      if (tapMarkerTimer <= 0) targetTapMarker = null;
    }
    if (caughtFlashTimer > 0) {
      caughtFlashTimer -= dt;
      if (caughtFlashTimer <= 0) onStateChanged();
    }
    if (_toastTimer > 0) {
      _toastTimer -= dt;
      if (_toastTimer <= 0) {
        toastMessage = null;
        onStateChanged();
      }
    }
    for (final d in _dust) {
      d.life -= dt;
      d.pos.add(d.vel * dt);
    }
    _dust.removeWhere((d) => d.life <= 0);
    if (isHintActive) {
      hintAnimProgress += dt * 0.8;
      if (hintAnimProgress > 1.0) hintAnimProgress = 0.0;
    }

    // Nothing in the world reacts unless the round is running.
    if (session.status != GameStatus.ready && session.status != GameStatus.moving) return;

    // Countdown timer
    if (session.remainingTime != null && session.remainingTime! > 0) {
      final before = session.remainingTime!.ceil();
      session.remainingTime = math.max(0.0, session.remainingTime! - dt);
      if (session.remainingTime!.ceil() != before) onStateChanged();
      if (session.remainingTime! <= 0) {
        session.status = GameStatus.gameOver;
        onStateChanged();
        return;
      }
    }

    // Power-up timers
    if (activeEffects.isNotEmpty) {
      final ended = <PowerUpKind>[];
      activeEffects.updateAll((k, v) => v - dt);
      activeEffects.forEach((k, v) {
        if (v <= 0) ended.add(k);
      });
      for (final k in ended) {
        activeEffects.remove(k);
      }
      if (ended.isNotEmpty) onStateChanged();
    }
    mouseComponent.speedMultiplier = activeEffects.containsKey(PowerUpKind.speed) ? 1.7 : 1.0;
    final invisible = activeEffects.containsKey(PowerUpKind.ghost);
    mouseComponent.isGhost = invisible;

    // Cats
    var anyCatAlert = false;
    var caught = false;
    for (final cat in catComponents) {
      cat.updateAI(
        dt: dt,
        mousePos: mouseComponent.position,
        mouseInvisible: invisible,
        onCaughtMouse: () => caught = true,
      );
      if (caught) break;
      if (cat.state == CatState.detect || cat.state == CatState.chase) anyCatAlert = true;
    }
    if (caught) {
      _loseLife('Caught by a cat');
      return;
    }
    if (mouseComponent.isAlert != anyCatAlert) {
      mouseComponent.isAlert = anyCatAlert;
      onStateChanged();
    }

    // Traps
    for (final obs in obstacleComponents) {
      if (obs.kind == ObstacleKind.trap &&
          !obs.isTriggered &&
          mouseComponent.position.distanceTo(obs.position) <= 14.0) {
        obs.trigger();
        _loseLife('Snap! A trap got you');
        return;
      }
    }

    // Cheese
    for (final cheese in cheeseComponents) {
      if (!cheese.isCollected && mouseComponent.position.distanceTo(cheese.position) <= 22.0) {
        cheese.collect();
        session.collectedCheese++;
        onStateChanged();
      }
    }

    // Power-ups
    for (final p in powerUpComponents) {
      if (!p.isCollected && mouseComponent.position.distanceTo(p.position) <= 22.0) {
        p.collect();
        _applyPowerUp(p.kind);
      }
    }

    // Goal
    if (mouseComponent.position.distanceTo(houseComponent.position) <= 24.0) {
      _completeLevel();
    }
  }

  void _applyPowerUp(PowerUpKind kind) {
    activeEffects[kind] = kind.duration;
    if (kind == PowerUpKind.freeze) {
      for (final c in catComponents) {
        c.freeze(kind.duration);
      }
    }
    showToast('${kind.emoji} ${kind.label}!');
  }

  /// Costs one heart and sends the mouse and every cat back to their starting
  /// positions. Collected cheese is kept.
  void _loseLife(String reason) {
    session.hearts = math.max(0, session.hearts - 1);
    lastLifeLostReason = reason;
    caughtFlashTimer = 1.6;
    mouseComponent.reset();
    for (final c in catComponents) {
      c.reset();
    }
    activeEffects.clear();
    breakMode = false;
    targetTapMarker = null;
    session.status = session.hearts <= 0 ? GameStatus.gameOver : GameStatus.ready;
    onStateChanged();
  }

  /// Watch Rewarded Video Ad to Continue Game
  void continueWithRewardedAd() {
    session.hearts = math.min(session.hearts + 1, session.maxHearts);
    if (session.remainingTime != null && session.remainingTime! <= 0) {
      session.remainingTime = 30.0;
    }
    session.status = GameStatus.ready;
    mouseComponent.reset();
    for (final c in catComponents) {
      c.reset();
    }
    onStateChanged();
  }

  void _completeLevel() {
    session.status = GameStatus.success;
    mouseComponent.stopMoving();
    mouseComponent.playVictoryAnimation();
    breakMode = false;

    final stars = ScoringSystem.calculateStars(
      reachedHouse: true,
      collectedCheese: session.collectedCheese,
      totalCheese: session.totalCheese,
      currentHearts: session.hearts,
      initialHearts: session.maxHearts,
    );
    ProgressService().recordLevelCompletion(levelNumber, stars, session.collectedCheese);
    onStateChanged();
  }

  // --------------------------------------------------------------------------
  // Canvas overlays (tap marker, hint path, break-mode highlight, dust)
  // --------------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(worldContainer.position.x, worldContainer.position.y);
    canvas.scale(worldContainer.scale.x);

    if (breakMode) {
      // Highlight every breakable wall/crate.
      final t = levelData.tileSize;
      final pulse = 0.55 + 0.35 * math.sin(_clock * 6);
      final fill = Paint()..color = const Color(0xFFFFB627).withValues(alpha: 0.18 * pulse);
      final paint = Paint()
        ..color = const Color(0xFFFFB627).withValues(alpha: pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      for (int y = 1; y < levelData.mapHeight - 1; y++) {
        for (int x = 1; x < levelData.mapWidth - 1; x++) {
          if (!walkGrid[y][x]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x * t + 3, y * t + 3, t - 6, t - 6), const Radius.circular(6)),
              paint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x * t + 3, y * t + 3, t - 6, t - 6), const Radius.circular(6)),
              fill,
            );
          }
        }
      }
    }

    if (targetTapMarker != null) {
      final pulseRadius = 12.0 + (1.0 - tapMarkerTimer) * 10.0;
      final alpha = tapMarkerTimer.clamp(0.0, 1.0);
      final c = Offset(targetTapMarker!.x, targetTapMarker!.y);
      canvas.drawCircle(
        c,
        pulseRadius,
        Paint()
          ..color = const Color(0xFF34E0C0).withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(c, 4.0, Paint()..color = const Color(0xFF34E0C0).withValues(alpha: alpha));
    }

    if (isHintActive && hintPath.length >= 2) {
      final p = Path()..moveTo(hintPath.first.x, hintPath.first.y);
      for (int i = 1; i < hintPath.length; i++) {
        p.lineTo(hintPath[i].x, hintPath[i].y);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFF8B7CFF).withValues(alpha: 0.55)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFEDE9FE).withValues(alpha: 0.9)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      final idx = ((hintPath.length - 1) * hintAnimProgress).floor();
      final next = math.min(idx + 1, hintPath.length - 1);
      final seg = ((hintPath.length - 1) * hintAnimProgress) - idx;
      final pos = hintPath[idx] + (hintPath[next] - hintPath[idx]) * seg;
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        10,
        Paint()
          ..color = const Color(0xFFFFC23D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(pos.x, pos.y), 5, Paint()..color = Colors.white);
    }

    for (final d in _dust) {
      canvas.drawCircle(
        Offset(d.pos.x, d.pos.y),
        3.5 * d.life / _BreakDust.maxLife + 1,
        Paint()..color = const Color(0xFFE7D7B5).withValues(alpha: (d.life / _BreakDust.maxLife).clamp(0.0, 1.0)),
      );
    }

    canvas.restore();
  }

  // --------------------------------------------------------------------------
  // Public controls
  // --------------------------------------------------------------------------
  void resetLevel() {
    session.reset();
    session.remainingTime = levelData.timeLimitSeconds.toDouble();
    mouseComponent.reset();
    targetTapMarker = null;
    tapMarkerTimer = 0.0;
    caughtFlashTimer = 0.0;
    toastMessage = null;
    hintPath.clear();
    isHintActive = false;
    _hintToken++;
    activeEffects.clear();
    breakMode = false;
    hammerCharges = levelData.hammerCharges;

    // Restore broken walls and crates.
    for (int y = 0; y < levelData.mapHeight; y++) {
      for (int x = 0; x < levelData.mapWidth; x++) {
        wallGrid[y][x] = levelData.walkableGrid[y][x];
        walkGrid[y][x] = wallGrid[y][x];
      }
    }
    for (final obs in obstacleComponents) {
      obs.reset();
      if (obs.kind != ObstacleKind.trap) {
        final g = _cellOf(obs.position);
        walkGrid[g.y][g.x] = false;
        if (obs.parent == null) worldContainer.add(obs);
      }
    }
    mazeComponent.markDirty();

    for (final cat in catComponents) {
      cat.reset();
    }
    for (final cheese in cheeseComponents) {
      cheese.reset();
    }
    for (final p in powerUpComponents) {
      p.reset();
    }
    onStateChanged();
  }

  void showHint() {
    hintPath.clear();
    final traps = <GridPoint>{
      for (final o in obstacleComponents)
        if (o.kind == ObstacleKind.trap && !o.isTriggered) _cellOf(o.position),
    };
    final path = navigationSystem.findPath(mouseComponent.position, houseComponent.destinationPoint, avoid: traps);
    hintPath.addAll(path.isNotEmpty ? path : levelData.solutionPath);
    isHintActive = true;
    hintAnimProgress = 0.0;
    onStateChanged();

    final token = ++_hintToken;
    Future.delayed(const Duration(seconds: 5), () {
      if (token != _hintToken) return;
      isHintActive = false;
      hintPath.clear();
      onStateChanged();
    });
  }
}

class _BreakDust {
  static const double maxLife = 0.6;
  final Vector2 pos;
  final Vector2 vel;
  double life = maxLife;
  _BreakDust(this.pos, this.vel);
}
