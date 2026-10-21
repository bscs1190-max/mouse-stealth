import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/cat_component.dart';
import 'models/cat_state.dart';
import 'models/game_state.dart';
import 'models/level_mechanics.dart';
import 'models/power_up.dart';
import 'rendering/code_game_components.dart';
import 'rendering/code_maze_component.dart';
import 'rendering/forest_background_component.dart';
import 'rendering/mechanic_components.dart';
import 'rendering/procedural_obstacle_component.dart';
import 'services/level_generator.dart';
import 'services/level_repository.dart';
import 'services/progress_service.dart';
import 'systems/collision_system.dart';
import 'systems/detection_system.dart';
import 'systems/navigation_system.dart';
import 'systems/scoring_system.dart';

class MouseHouseGame extends FlameGame {
  final int levelNumber;
  final VoidCallback onStateChanged;

  MouseHouseGame({required this.levelNumber, required this.onStateChanged}) : super();

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

  // Extra mechanics
  KeyComponent? keyComponent;
  GateComponent? gateComponent;
  WallSwitchComponent? switchComponent;
  bool hasKey = false;
  bool gateOpen = false;
  bool pendingPress = false; // mouse is walking to the wall button

  // First-level hand guide: step 0 is a demo tap, the next steps are the player's own taps.
  List<Vector2> guideTargets = [];
  int guideStep = -1; // -1 = off
  bool _guideWalking = false;
  double _guideClock = 0.0;
  bool get guideActive => guideStep >= 0;
  double _lockedToastCooldown = 0.0;

  // Camera (pinch to zoom, drag to pan; starts on the whole map)
  double _scale = 1.0;
  Vector2 _camPos = Vector2.zero();
  bool _userMovedCamera = false;
  double _topInset = 135.0;
  double _bottomInset = 95.0;

  LevelDifficulty get difficulty => LevelGenerator.difficultyFor(levelNumber);

  /// Short reminders for the intro card. New mechanics get an animated demo instead
  /// (see demosForLevel), so only level-specific facts are listed here.
  List<String> get introNotes {
    final notes = <String>[];
    if (levelNumber == 5) notes.add('First MEDIUM level: 2 cats on patrol.');
    if (levelNumber == 10) notes.add('First HARD level: 3 cats and a bigger maze.');
    if (levelData.keyPosition != null && levelNumber != LevelMechanics.firstKeyLevel) {
      notes.add('The house is LOCKED. Find the golden key first!');
    }
    if (levelData.gate != null && levelNumber != LevelMechanics.firstGateLevel) {
      notes.add('A gate blocks the way. Tap the glowing wall button to open it.');
    }
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
    wallGrid = [
      for (final row in levelData.walkableGrid) [...row],
    ];
    walkGrid = [
      for (final row in wallGrid) [...row],
    ];
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

    // Extra mechanics (hard/medium levels): locked house with key, gate with wall button.
    final key = levelData.keyPosition;
    if (key != null) {
      keyComponent = KeyComponent(position: key);
      worldContainer.add(keyComponent!);
      houseComponent.locked = true;
    }
    final g = levelData.gate;
    if (g != null) {
      final tile = levelData.tileSize;
      gateComponent = GateComponent(position: g.gate, tile: tile);
      switchComponent = WallSwitchComponent(position: g.switchWall, tile: tile);
      worldContainer.add(gateComponent!);
      worldContainer.add(switchComponent!);
      final gc = _cellOf(g.gate);
      walkGrid[gc.y][gc.x] = false; // closed until the button is pressed
    }

    for (final catCfg in levelData.cats) {
      final cat = CatComponent(config: catCfg, nav: navigationSystem, detection: detectionSystem);
      catComponents.add(cat);
      worldContainer.add(cat);
    }

    mouseComponent = CodeMouseComponent(spawnPosition: levelData.mouseSpawn);
    worldContainer.add(mouseComponent);

    add(worldContainer);
    _refitCamera();
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
    _beginGuide();
    onStateChanged();
  }

  // --------------------------------------------------------------------------
  // CAMERA: starts on the whole map; pinch to zoom, drag to pan.
  // --------------------------------------------------------------------------
  static const double _margin = 12.0;
  static const double _maxScale = 2.6;

  /// Space (in logical pixels) taken by the HUD above and below the board.
  void setViewportInsets({required double top, required double bottom}) {
    if ((top - _topInset).abs() < 0.5 && (bottom - _bottomInset).abs() < 0.5) return;
    _topInset = top;
    _bottomInset = bottom;
    _refitCamera();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _refitCamera();
  }

  double get _availW => size.x - _margin * 2;
  double get _availH => math.max(100.0, size.y - (_topInset + _bottomInset));

  /// Scale at which the entire map is visible.
  double get fitScale => math.min(_availW / mapPixelSize.x, _availH / mapPixelSize.y);

  /// Zoom relative to the full-map view (1.0 = whole map visible).
  double get zoomLevel => _scale / fitScale;

  void _refitCamera() {
    if (!isLoaded) return;
    if (!_userMovedCamera) {
      _scale = fitScale;
      _camPos = Vector2.zero();
    }
    _applyCamera();
  }

  /// Back to the full-map view.
  void resetCamera() {
    _userMovedCamera = false;
    _refitCamera();
    onStateChanged();
  }

  /// Clamps the camera so the map can never be dragged out of view.
  void _applyCamera() {
    final fit = fitScale;
    _scale = _scale.clamp(fit, math.max(_maxScale, fit));
    double axis(double avail, double start, double mapLen, double pos) {
      final len = mapLen * _scale;
      if (len <= avail) return start + (avail - len) / 2;
      return pos.clamp(start + avail - len, start);
    }

    final x = axis(_availW, _margin, mapPixelSize.x, _camPos.x);
    final y = axis(_availH, _topInset, mapPixelSize.y, _camPos.y);
    _camPos = Vector2(x, y);
    worldContainer.scale = Vector2.all(_scale);
    worldContainer.position = _camPos.clone();
  }

  /// Pinch: multiply the zoom by [factor] around the screen point [focal].
  void pinchZoom(Vector2 focal, double factor) {
    if (!isLoaded) return;
    _userMovedCamera = true;
    final before = (focal - worldContainer.position) / worldContainer.scale.x;
    _scale = (_scale * factor).clamp(fitScale, math.max(_maxScale, fitScale));
    _camPos = focal - before * _scale;
    _applyCamera();
  }

  /// Drag: move the map by [delta] screen pixels.
  void panBy(Vector2 delta) {
    if (!isLoaded) return;
    _userMovedCamera = true;
    _camPos = worldContainer.position + delta;
    _applyCamera();
  }

  Vector2 _screenToWorld(Vector2 screenPosition) => (screenPosition - worldContainer.position) / worldContainer.scale.x;

  // --------------------------------------------------------------------------
  // INPUT (taps are detected by the game screen, which also owns pinch/pan)
  // --------------------------------------------------------------------------
  void handleTap(Vector2 canvasPosition) {
    if (!isLoaded) return;
    if (session.status != GameStatus.ready && session.status != GameStatus.moving) return;

    var worldPos = _screenToWorld(canvasPosition);
    if (worldPos.x < 0 || worldPos.y < 0 || worldPos.x >= mapPixelSize.x || worldPos.y >= mapPixelSize.y) {
      return; // Tapped outside the map
    }
    var gridPt = navigationSystem.worldToGrid(worldPos);

    // Hand guide: only the highlighted spot is accepted, and the demo ignores taps.
    if (guideActive && !breakMode) {
      if (guideStep == 0 || _guideWalking) return;
      final target = guideTargets[guideStep];
      final tc = _cellOf(target);
      if ((gridPt.x - tc.x).abs() + (gridPt.y - tc.y).abs() > 1) {
        showToast('Tap the spot where the hand points');
        return;
      }
      worldPos = target.clone();
      gridPt = tc;
      _guideWalking = true;
    }

    if (breakMode) {
      _tryBreak(gridPt);
      return;
    }

    // Wall button: the mouse walks to it and presses it.
    final sw = levelData.gate;
    if (sw != null && gridPt == _cellOf(sw.switchWall)) {
      _tapSwitch(sw);
      return;
    }
    pendingPress = false;

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
    } else if (guideActive) {
      _guideWalking = false; // nothing to walk: let the player try again
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
    final mech = levelData.gate;
    if (mech != null && (g == _cellOf(mech.gate) || g == _cellOf(mech.switchWall))) {
      showToast('Reinforced! Use the wall button instead');
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

  // --------------------------------------------------------------------------
  // FIRST-LEVEL HAND GUIDE
  // A hand taps a spot and the mouse walks there (demo), then the player taps
  // the next highlighted spots themselves until they have the idea.
  // --------------------------------------------------------------------------
  void _beginGuide() {
    guideStep = -1;
    guideTargets = [];
    _guideWalking = false;
    if (levelNumber != 1 || ProgressService().moveGuideDone) return;

    final t = levelData.tileSize;
    // A cell is unsafe when any cat on its patrol could see it (radar range + line of sight).
    bool seenByCats(Vector2 p) {
      for (final cat in catComponents) {
        final range = cat.config.visionRange + t * 0.8;
        for (final r in cat.patrolRoute) {
          if (r.distanceTo(p) <= range && detectionSystem.hasLineOfSight(r, p)) return true;
        }
      }
      return false;
    }

    // Take spots from the stretch of route BEFORE any cat can see it, so the
    // demo walk and the player's taps can never run into a cat.
    final safeRoute = <Vector2>[];
    for (final p in levelData.solutionPath) {
      final c = navigationSystem.gridToWorld(navigationSystem.worldToGrid(p));
      if (seenByCats(c)) break;
      safeRoute.add(c);
    }
    for (final spacing in [4.0, 2.5, 1.8]) {
      guideTargets = [];
      for (final c in safeRoute) {
        if (guideTargets.length >= 3) break;
        if (c.distanceTo(mouseComponent.position) < t * spacing) continue;
        if (guideTargets.isNotEmpty && guideTargets.last.distanceTo(c) < t * spacing) continue;
        guideTargets.add(c);
      }
      if (guideTargets.length >= 2) break;
    }
    if (guideTargets.length < 2) {
      guideTargets = [];
      return;
    }
    guideStep = 0;
    _guideClock = 0;
    showToast('Watch: tap a spot and the mouse walks there');
  }

  void _endGuide() {
    if (guideStep < 0) return;
    guideStep = -1;
    _guideWalking = false;
    ProgressService().moveGuideDone = true;
  }

  void _guideWalk(Vector2 target) {
    final path = navigationSystem.findPath(mouseComponent.position, target, avoid: _activeTraps());
    if (path.isEmpty) {
      _endGuide();
      return;
    }
    _guideWalking = true;
    session.status = GameStatus.moving;
    targetTapMarker = target.clone();
    tapMarkerTimer = 1.0;
    mouseComponent.navigateToPath(path);
    onStateChanged();
  }

  void _updateGuide(double dt) {
    _guideClock += dt;
    if (guideStep == 0 && !_guideWalking && _guideClock > 2.2) {
      _guideWalk(guideTargets[0]); // the "finger" taps for the player
    }
    if (_guideWalking && !mouseComponent.isMoving) {
      _guideWalking = false;
      guideStep++;
      _guideClock = 0;
      if (guideStep >= guideTargets.length) {
        _endGuide();
        showToast('You got it! Collect the cheese, avoid the radar, reach the house');
      } else {
        showToast(
          guideStep == guideTargets.length - 1
              ? 'Last one: tap where the hand points'
              : 'Your turn: tap where the hand points',
        );
      }
      onStateChanged();
    }
  }

  void _drawGuideHand(Canvas canvas) {
    if (!guideActive || _guideWalking) return;
    final target = guideTargets[guideStep];
    final c = Offset(target.x, target.y);
    final pulse = 0.5 + 0.5 * math.sin(_clock * 5);
    // Glowing target tile
    canvas.drawCircle(
      c,
      15 + pulse * 5,
      Paint()..color = const Color(0xFFFFC23D).withValues(alpha: 0.18 + pulse * 0.15),
    );
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..color = const Color(0xFFFFC23D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // The hand dips onto the tile (a tap) and lifts again.
    final dip = (math.sin(_clock * 6) * 0.5 + 0.5);
    final handCentre = c + Offset(10, 18 - 12 * dip);
    if (dip > 0.85) {
      canvas.drawCircle(
        c,
        10 + (dip - 0.85) * 120,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final icon = Icons.touch_app_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 34,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, handCentre - Offset(tp.width * 0.35, tp.height * 0.15));
    // Label bubble
    final label = TextPainter(
      text: TextSpan(
        text: guideStep == 0 ? 'Watch' : 'Tap here!',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bubble = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + const Offset(0, -30), width: label.width + 18, height: 22),
      const Radius.circular(11),
    );
    canvas.drawRRect(bubble, Paint()..color = const Color(0xE65A46E0));
    label.paint(canvas, bubble.center - Offset(label.width / 2, label.height / 2));
  }

  // --------------------------------------------------------------------------
  // GATE + WALL BUTTON, KEY
  // --------------------------------------------------------------------------
  Set<GridPoint> _activeTraps() => {
    for (final o in obstacleComponents)
      if (o.kind == ObstacleKind.trap && !o.isTriggered) _cellOf(o.position),
  };

  /// The mouse walks next to the button and presses it.
  void _tapSwitch(GatePlacement g) {
    if (gateOpen) {
      showToast('The gate is already open');
      return;
    }
    final spot = g.pressSpot;
    if (mouseComponent.position.distanceTo(spot) <= 8) {
      _openGate();
      return;
    }
    final path = navigationSystem.findPath(mouseComponent.position, spot, avoid: _activeTraps());
    if (path.isEmpty) {
      showToast('You cannot reach the button');
      return;
    }
    pendingPress = true;
    session.status = GameStatus.moving;
    targetTapMarker = spot.clone();
    tapMarkerTimer = 1.0;
    mouseComponent.navigateToPath(path);
    showToast('Heading to the button...');
  }

  void _openGate() {
    final g = levelData.gate;
    if (g == null || gateOpen) return;
    gateOpen = true;
    pendingPress = false;
    final c = _cellOf(g.gate);
    walkGrid[c.y][c.x] = true; // collision, pathfinding and cat sight all share this grid
    gateComponent?.isOpen = true;
    switchComponent?.pressed = true;
    showToast('Click! The gate is open');
  }

  void _closeGate() {
    final g = levelData.gate;
    if (g == null) return;
    gateOpen = false;
    pendingPress = false;
    final c = _cellOf(g.gate);
    walkGrid[c.y][c.x] = false;
    gateComponent?.reset();
    switchComponent?.reset();
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

    // Countdown timer (paused while the hand guide teaches the controls)
    if (guideActive) _updateGuide(dt);
    if (!guideActive && session.remainingTime != null && session.remainingTime! > 0) {
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

    // Key
    final keyComp = keyComponent;
    if (keyComp != null && !keyComp.isCollected && mouseComponent.position.distanceTo(keyComp.position) <= 22.0) {
      keyComp.collect();
      hasKey = true;
      houseComponent.locked = false;
      showToast('Key found! The house is unlocked');
    }

    // Wall button: press it once the mouse has arrived at the press spot.
    final gate = levelData.gate;
    if (pendingPress && gate != null && !mouseComponent.isMoving) {
      if (mouseComponent.position.distanceTo(gate.pressSpot) <= 10) {
        _openGate();
      } else {
        pendingPress = false; // the walk was interrupted
      }
    }

    // Goal
    if (_lockedToastCooldown > 0) _lockedToastCooldown -= dt;
    if (mouseComponent.position.distanceTo(houseComponent.position) <= 24.0) {
      if (houseComponent.locked) {
        if (_lockedToastCooldown <= 0) {
          _lockedToastCooldown = 2.5;
          showToast('The house is locked! Find the key');
        }
      } else {
        _completeLevel();
      }
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
    _endGuide(); // a caught mouse has clearly learned the controls
    breakMode = false;
    pendingPress = false;
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

    _drawGuideHand(canvas);

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
    _beginGuide(); // restarts the first-level hand guide if it was not finished
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

    // Key, gate and wall button start over.
    hasKey = false;
    keyComponent?.reset();
    houseComponent.locked = keyComponent != null;
    _lockedToastCooldown = 0;
    _closeGate();

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
    // Point at the next objective: key, then the wall button, then the house.
    Vector2 target = houseComponent.destinationPoint;
    String? say;
    final keyComp = keyComponent;
    final gate = levelData.gate;
    if (keyComp != null && !hasKey) {
      target = keyComp.position;
      say = 'Find the golden key first';
    } else if (gate != null && !gateOpen) {
      target = gate.pressSpot;
      say = 'Tap the glowing wall button to open the gate';
    }
    if (say != null) showToast(say);
    final path = navigationSystem.findPath(mouseComponent.position, target, avoid: _activeTraps());
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
