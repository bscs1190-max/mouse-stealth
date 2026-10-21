class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  int totalCheeseCurrency = 0;
  int highestUnlockedLevel = 1;
  bool tutorialSeen = false; // the first-level guide is shown until finished or skipped
  bool moveGuideDone = false; // the on-map hand guide of level 1 has been completed
  final Map<int, int> levelStars = {};

  void addCheese(int count) {
    totalCheeseCurrency += count;
  }

  bool deductCheese(int count) {
    if (totalCheeseCurrency >= count) {
      totalCheeseCurrency -= count;
      return true;
    }
    return false;
  }

  void recordLevelCompletion(int level, int stars, int cheeseCount) {
    totalCheeseCurrency += cheeseCount;
    if ((levelStars[level] ?? 0) < stars) {
      levelStars[level] = stars;
    }
    if (level >= highestUnlockedLevel) {
      highestUnlockedLevel = level + 1;
    }
  }
}
