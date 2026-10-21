import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/models/game_state.dart';
import '../game/mouse_house_game.dart';
import '../game/systems/scoring_system.dart';
import '../game/services/progress_service.dart';
import '../ui/demo/demo_scene.dart';
import '../ui/game_over_dialog.dart';
import '../ui/hud_overlay.dart';
import '../ui/level_complete_dialog.dart';
import '../ui/tutorial_overlay.dart';

class GameScreen extends StatefulWidget {
  final int levelNumber;

  const GameScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int currentLevel;
  late MouseHouseGame _game;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.levelNumber;
    _initGame();
  }

  void _initGame() {
    _game = MouseHouseGame(
      levelNumber: currentLevel,
      onStateChanged: _refresh,
    );
  }

  bool _refreshQueued = false;

  /// Rebuilds the HUD. Flame can run a game tick while Flutter is still
  /// building/laying out (e.g. on the first frame or a resize), and calling
  /// setState then throws, so in that case the rebuild waits for the frame end.
  void _refresh() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final midFrame = phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.midFrameMicrotasks;
    if (!midFrame) {
      setState(() {});
      return;
    }
    if (_refreshQueued) return;
    _refreshQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      if (mounted) setState(() {});
    });
  }

  // --------------------------------------------------------------------------
  // Touch: tap = move, one finger drag = pan, two fingers = pinch zoom,
  // mouse wheel = zoom (desktop / web).
  // --------------------------------------------------------------------------
  final Map<int, Offset> _pointers = {};
  int? _tapPointer;
  Offset _downPos = Offset.zero;
  DateTime _downTime = DateTime.now();
  bool _dragging = false;
  double _lastSpan = 0;
  Offset _lastFocal = Offset.zero;

  Vector2 _v(Offset o) => Vector2(o.dx, o.dy);

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _tapPointer = e.pointer;
      _downPos = e.localPosition;
      _downTime = DateTime.now();
      _dragging = false;
    } else {
      _tapPointer = null; // a second finger turns this into a pinch
      _startPinch();
    }
  }

  void _startPinch() {
    final p = _pointers.values.take(2).toList();
    _lastSpan = (p[0] - p[1]).distance;
    _lastFocal = (p[0] + p[1]) / 2;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer) || !_game.isLoaded) return;
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length >= 2) {
      final p = _pointers.values.take(2).toList();
      final span = (p[0] - p[1]).distance;
      final focal = (p[0] + p[1]) / 2;
      if (_lastSpan > 8) _game.pinchZoom(_v(focal), span / _lastSpan);
      _game.panBy(_v(focal - _lastFocal));
      _lastSpan = span;
      _lastFocal = focal;
    } else {
      if (!_dragging && (e.localPosition - _downPos).distance > 10) _dragging = true;
      if (_dragging) _game.panBy(_v(e.delta));
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    final isTap = _tapPointer == e.pointer &&
        !_dragging &&
        _pointers.length == 1 &&
        DateTime.now().difference(_downTime).inMilliseconds < 600;
    _pointers.remove(e.pointer);
    if (isTap) _game.handleTap(_v(e.localPosition));
    _endGestureIfIdle();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _endGestureIfIdle();
  }

  void _endGestureIfIdle() {
    _tapPointer = null;
    _lastSpan = 0;
    // The remaining finger keeps panning after a pinch.
    _dragging = _pointers.isNotEmpty;
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent && _game.isLoaded) {
      _game.pinchZoom(_v(e.localPosition), math.exp(-e.scrollDelta.dy / 400));
    }
  }

  void _loadNextLevel() {
    if (_game.session.status != GameStatus.success) return; // ignore double taps
    if (currentLevel < 100) {
      setState(() {
        currentLevel++;
        _initGame();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 You conquered all 100 levels!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _game.isLoaded ? _game.session : null;
    final status = session?.status;
    final isOver = status == GameStatus.success || status == GameStatus.gameOver || status == GameStatus.paused;

    // Keep the board between the HUD bars on every device.
    final pad = MediaQuery.paddingOf(context);
    if (_game.isLoaded) {
      _game.setViewportInsets(top: pad.top + HudMetrics.top + 8, bottom: pad.bottom + HudMetrics.bottom);
    }

    return Scaffold(
      body: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            onPointerSignal: _onPointerSignal,
            child: GameWidget(key: ValueKey(currentLevel), game: _game),
          ),

          if (session != null)
            HudOverlay(
              levelData: _game.levelData,
              session: session,
              keyCollected: _game.keyComponent == null ? null : _game.hasKey,
              gateOpen: _game.gateComponent == null ? null : _game.gateOpen,
              spotted: _game.mouseComponent.isAlert,
              lifeLostMessage: _game.caughtFlashTimer > 0 ? _game.lastLifeLostReason : null,
              toastMessage: _game.toastMessage,
              activeEffects: Map.of(_game.activeEffects),
              hammerCharges: _game.hammerCharges,
              breakMode: _game.breakMode,
              onFitPressed: _game.resetCamera,
              onHintPressed: _game.showHint,
              onResetPressed: _game.resetLevel,
              onBreakPressed: _game.toggleBreakMode,
              onBackPressed: () => Navigator.of(context).pop(),
            ),

          // Dimmed backdrop behind cards
          IgnorePointer(
            ignoring: !isOver,
            child: AnimatedOpacity(
              opacity: isOver ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),

          if (status == GameStatus.paused && currentLevel == 1 && !ProgressService().tutorialSeen)
            TutorialOverlay(
              onDone: () {
                ProgressService().tutorialSeen = true;
                _game.startLevel();
              },
            )
          else if (status == GameStatus.paused)
            SafeArea(
              child: LevelIntroCard(
                levelData: _game.levelData,
                notes: _game.introNotes,
                demos: demosForLevel(currentLevel),
                onStart: _game.startLevel,
              ),
            ),

          if (status == GameStatus.success)
            LevelCompleteDialog(
              stars: ScoringSystem.calculateStars(
                reachedHouse: true,
                collectedCheese: session!.collectedCheese,
                totalCheese: session.totalCheese,
                currentHearts: session.hearts,
                initialHearts: session.maxHearts,
              ),
              collectedCheese: session.collectedCheese,
              totalCheese: session.totalCheese,
              onReplay: _game.resetLevel,
              onNextLevel: _loadNextLevel,
            ),

          if (status == GameStatus.gameOver)
            GameOverDialog(
              timeUp: session!.hearts > 0,
              onWatchAdContinue: _game.continueWithRewardedAd,
              onRestart: _game.resetLevel,
              onBackToLevels: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}
