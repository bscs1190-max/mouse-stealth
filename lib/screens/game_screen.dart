import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/models/game_state.dart';
import '../game/mouse_house_game.dart';
import '../game/systems/scoring_system.dart';
import '../ui/game_over_dialog.dart';
import '../ui/hud_overlay.dart';
import '../ui/level_complete_dialog.dart';

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
          GameWidget(key: ValueKey(currentLevel), game: _game),

          if (session != null)
            HudOverlay(
              levelData: _game.levelData,
              session: session,
              currentZoom: _game.userZoomFactor,
              spotted: _game.mouseComponent.isAlert,
              lifeLostMessage: _game.caughtFlashTimer > 0 ? _game.lastLifeLostReason : null,
              toastMessage: _game.toastMessage,
              activeEffects: Map.of(_game.activeEffects),
              hammerCharges: _game.hammerCharges,
              breakMode: _game.breakMode,
              onZoomIn: _game.zoomIn,
              onZoomOut: _game.zoomOut,
              onResetZoom: _game.resetZoom,
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

          if (status == GameStatus.paused)
            SafeArea(
              child: LevelIntroCard(
                levelData: _game.levelData,
                notes: _game.introNotes,
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
