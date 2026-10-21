import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/theme_config.dart';
import '../game/services/level_generator.dart';
import '../game/services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/game_ui.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

/// One row of the road: either a world banner or a level node.
class _Entry {
  final int? level;
  final int world;
  const _Entry.level(int this.level, this.world);
  const _Entry.header(this.world) : level = null;
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final progress = ProgressService();
  final _scrollController = ScrollController();
  late final List<_Entry> _entries;

  static const double rowHeight = 112;
  static const double headerHeight = 96;

  static const _worldIcon = [
    Icons.park_rounded,
    Icons.eco_rounded,
    Icons.diamond_rounded,
    Icons.forest_rounded,
    Icons.ac_unit_rounded,
    Icons.volcano_rounded,
    Icons.wb_sunny_rounded,
    Icons.location_city_rounded,
    Icons.nights_stay_rounded,
    Icons.auto_awesome_rounded,
  ];
  static const _scenery = [
    [Icons.park_rounded, Icons.forest_rounded, Icons.grass_rounded, Icons.spa_rounded],
    [Icons.eco_rounded, Icons.local_florist_rounded, Icons.park_rounded, Icons.grass_rounded],
    [Icons.diamond_rounded, Icons.auto_awesome_rounded, Icons.landscape_rounded, Icons.hexagon_rounded],
    [Icons.forest_rounded, Icons.local_florist_rounded, Icons.emoji_nature_rounded, Icons.grass_rounded],
    [Icons.ac_unit_rounded, Icons.landscape_rounded, Icons.cloud_rounded, Icons.severe_cold_rounded],
    [Icons.volcano_rounded, Icons.local_fire_department_rounded, Icons.whatshot_rounded, Icons.terrain_rounded],
    [Icons.wb_sunny_rounded, Icons.terrain_rounded, Icons.landscape_rounded, Icons.filter_hdr_rounded],
    [Icons.location_city_rounded, Icons.memory_rounded, Icons.satellite_alt_rounded, Icons.bolt_rounded],
    [Icons.nights_stay_rounded, Icons.church_rounded, Icons.cloud_rounded, Icons.park_rounded],
    [Icons.star_rounded, Icons.nightlight_round, Icons.auto_awesome_rounded, Icons.brightness_7_rounded],
  ];
  // Horizontal position of each node in the zig-zag (-1..1).
  static const _wave = [0.0, 0.5, 0.78, 0.5, 0.0, -0.5, -0.78, -0.5];

  @override
  void initState() {
    super.initState();
    _entries = [
      for (int lvl = 1; lvl <= 100; lvl++) ...[
        if (lvl % 10 == 1) _Entry.header((lvl - 1) ~/ 10),
        _Entry.level(lvl, (lvl - 1) ~/ 10),
      ],
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  double _offsetOf(int entryIndex) {
    var y = 0.0;
    for (int i = 0; i < entryIndex; i++) {
      y += _entries[i].level == null ? headerHeight : rowHeight;
    }
    return y;
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final target = progress.highestUnlockedLevel.clamp(1, 100);
    final idx = _entries.indexWhere((e) => e.level == target);
    final pos = _scrollController.position;
    final offset = (_offsetOf(idx) - pos.viewportDimension / 2 + rowHeight / 2).clamp(0.0, pos.maxScrollExtent);
    _scrollController.animateTo(offset, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _play(int level) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameScreen(levelNumber: level)))
        .then((_) => setState(() {}));
  }

  /// Alignment that centres a node of width [cw] on the road at fraction [x].
  static double _nodeAlign(double x, double w, double cw) => w <= cw ? 0 : x * 0.9 * (w / 2 - 40) / ((w - cw) / 2);

  /// x position (fraction -1..1) of the road at entry [i].
  double _xAt(int i) {
    i = i.clamp(0, _entries.length - 1);
    final e = _entries[i];
    if (e.level == null) {
      // Banner rows sit between two levels (or before level 1).
      double lv(int j) => _wave[(_entries[j].level! - 1) % _wave.length];
      final next = lv(i + 1);
      return i == 0 ? next : (lv(i - 1) + next) / 2;
    }
    return _wave[(e.level! - 1) % _wave.length];
  }

  @override
  Widget build(BuildContext context) {
    final cleared = progress.levelStars.length;
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level Road', style: AppText.display(26)),
                          Text('$cleared of 100 cleared', style: AppText.body(12.5)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const ShopScreen()))
                              .then((_) => setState(() {})),
                      child: CheeseCounter(amount: progress.totalCheeseCurrency),
                    ),
                  ],
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _LegendDot(tag: 'EASY', label: 'Easy · 1 cat'),
                    SizedBox(width: 12),
                    _LegendDot(tag: 'MEDIUM', label: 'Medium · 2'),
                    SizedBox(width: 12),
                    _LegendDot(tag: 'HARD', label: 'Hard · 3'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 40 + MediaQuery.paddingOf(context).bottom),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    return e.level == null ? _buildHeader(i, e.world) : _buildLevelRow(i, e.level!, e.world);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _worldBackdrop({required int world, required double height, required Widget child, required int i}) {
    final theme = ThemeConfig.forLevel(world * 10 + 1);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Tinted world zone
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    theme.wallBottom.withValues(alpha: 0.28),
                    theme.bgGradient.first.withValues(alpha: 0.05),
                    theme.wallBottom.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          // Road segment
          Positioned.fill(
            child: CustomPaint(
              painter: _RoadPainter(
                fromX: (_xAt(i - 1) + _xAt(i)) / 2,
                midX: _xAt(i),
                toX: (_xAt(i) + _xAt(i + 1)) / 2,
                unlocked: _entries[i].level == null
                    ? (world * 10 + 1) <= progress.highestUnlockedLevel
                    : _entries[i].level! <= progress.highestUnlockedLevel,
                edge: theme.wallHighlight,
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildHeader(int i, int world) {
    final theme = ThemeConfig.forLevel(world * 10 + 1);
    final first = world * 10 + 1;
    final locked = first > progress.highestUnlockedLevel;
    return _worldBackdrop(
      world: world,
      height: headerHeight,
      i: i,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.wallTop, theme.wallBottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.wallHighlight.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle),
                child: Icon(_worldIcon[world], color: theme.lanternGlass, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORLD ${world + 1}',
                      style: AppText.body(11, color: Colors.white70).copyWith(letterSpacing: 2),
                    ),
                    Text(
                      theme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (locked)
                const Icon(Icons.lock_rounded, color: Colors.white60)
              else
                Text('$first–${first + 9}', style: AppText.number(14, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow(int i, int levelNum, int world) {
    final unlocked = levelNum <= progress.highestUnlockedLevel;
    final isCurrent = levelNum == progress.highestUnlockedLevel;
    final stars = progress.levelStars[levelNum] ?? 0;
    final diff = LevelGenerator.difficultyFor(levelNum);
    final tagColor = difficultyColor(diff.tag);
    final nodeSize = switch (diff) {
      LevelDifficulty.hard => 72.0,
      LevelDifficulty.medium => 64.0,
      LevelDifficulty.easy => 56.0,
    };
    final x = _xAt(i);

    // Scenery on the side away from the node (deterministic per level).
    final rand = math.Random(levelNum * 31);
    final props = _scenery[world];
    final theme = ThemeConfig.forLevel(levelNum);
    final sceneColor = Color.lerp(theme.treeFoliageMid, theme.wallHighlight, 0.6)!;
    final sideX = x > 0 ? -0.82 + rand.nextDouble() * 0.25 : 0.57 + rand.nextDouble() * 0.25;
    final prop1 = props[rand.nextInt(props.length)];
    final prop2 = props[rand.nextInt(props.length)];

    final List<Color> colors = !unlocked
        ? const [AppColors.surfaceHigh, AppColors.surface]
        : [Color.lerp(tagColor, Colors.white, 0.15)!, Color.lerp(tagColor, Colors.black, 0.3)!];

    return _worldBackdrop(
      world: world,
      height: rowHeight,
      i: i,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Align(
              alignment: Alignment(sideX, -0.4),
              child: Opacity(
                opacity: 0.85,
                child: Icon(prop1, color: Color.lerp(sceneColor, Colors.white, 0.1), size: 26 + rand.nextDouble() * 12),
              ),
            ),
            Align(
              alignment: Alignment(sideX + (x > 0 ? 0.22 : -0.22), 0.6),
              child: Opacity(opacity: 0.6, child: Icon(prop2, color: sceneColor, size: 18)),
            ),
            Align(
              alignment: Alignment(_nodeAlign(x, box.maxWidth, nodeSize + 40), 0),
              child: GestureDetector(
                onTap: unlocked ? () => _play(levelNum) : null,
                child: SizedBox(
                  width: nodeSize + 40,
                  height: rowHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (isCurrent)
                            Container(
                              width: nodeSize + 16,
                              height: nodeSize + 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.mint, width: 3),
                                boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.55), blurRadius: 20)],
                              ),
                            ),
                          // 3D base
                          Transform.translate(
                            offset: const Offset(0, 5),
                            child: Container(
                              width: nodeSize,
                              height: nodeSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: unlocked ? Color.lerp(tagColor, Colors.black, 0.55) : AppColors.bgBottom,
                              ),
                            ),
                          ),
                          Container(
                            width: nodeSize,
                            height: nodeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: unlocked ? Colors.white.withValues(alpha: 0.85) : AppColors.outline,
                                width: unlocked ? 3 : 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: unlocked
                                ? Text(
                                    '$levelNum',
                                    style: AppText.display(diff == LevelDifficulty.easy ? 21 : 24, color: Colors.white),
                                  )
                                : const Icon(Icons.lock_rounded, color: AppColors.textFaint, size: 22),
                          ),
                          if (diff != LevelDifficulty.easy)
                            Positioned(
                              top: -10,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  diff == LevelDifficulty.hard ? Icons.whatshot_rounded : Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          if (isCurrent)
                            Positioned(
                              top: -24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('PLAY', style: AppText.title(11, color: AppColors.bgBottom)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      if (unlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.bgBottom.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: StarRow(stars: stars, size: 13),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws one segment of the winding dirt road through a row.
class _RoadPainter extends CustomPainter {
  final double fromX, midX, toX;
  final bool unlocked;
  final Color edge;

  _RoadPainter({
    required this.fromX,
    required this.midX,
    required this.toX,
    required this.unlocked,
    required this.edge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double px(double f) => size.width / 2 + f * 0.9 * (size.width / 2 - 40);
    final path = Path()
      ..moveTo(px(fromX), 0)
      ..quadraticBezierTo(px(midX), size.height * 0.15, px(midX), size.height / 2)
      ..quadraticBezierTo(px(midX), size.height * 0.85, px(toX), size.height);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = unlocked ? const Color(0xFF8A6A3D) : const Color(0xFF3A3F63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );
    // Dashed centre line
    final dash = Paint()
      ..color = unlocked ? AppColors.cheese.withValues(alpha: 0.9) : edge.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (double d = 4; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 7, metric.length)), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.fromX != fromX || old.midX != midX || old.toX != toX || old.unlocked != unlocked;
}

class _LegendDot extends StatelessWidget {
  final String tag;
  final String label;
  const _LegendDot({required this.tag, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: difficultyColor(tag), shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.body(12)),
      ],
    );
  }
}
