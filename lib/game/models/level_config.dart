class LevelConfig {
  final int levelNumber;
  final String title;
  final String tmxFile;
  final int totalCheese;
  final int initialHearts;
  final bool timerEnabled;
  final double? timeLimit;
  final List<String> supportedObstacles;

  const LevelConfig({
    required this.levelNumber,
    required this.title,
    required this.tmxFile,
    this.totalCheese = 3,
    this.initialHearts = 3,
    this.timerEnabled = false,
    this.timeLimit,
    this.supportedObstacles = const [],
  });
}
