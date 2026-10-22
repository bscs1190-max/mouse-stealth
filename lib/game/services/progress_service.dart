class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  int totalCheeseCurrency = 0;
  int highestUnlockedLevel = 1;
  bool tutorialSeen = true; // Skip redundant multi-page tutorial screens; in-game animated hand guides the gameplay directly!
  bool moveGuideDone = false; // the on-map hand guide of level 1 has been completed
  int? playerAge;
  bool get hasSetAge => playerAge != null;
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
