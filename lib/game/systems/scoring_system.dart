class ScoringSystem {
  static int calculateStars({
    required bool reachedHouse,
    required int collectedCheese,
    required int totalCheese,
    required int currentHearts,
    required int initialHearts,
  }) {
    if (!reachedHouse) return 0;

    // 3 Stars: Reached house + collected all cheese + full hearts
    if (collectedCheese == totalCheese && currentHearts == initialHearts) {
      return 3;
    }

    // 2 Stars: Reached house + collected some cheese
    if (collectedCheese > 0) {
      return 2;
    }

    // 1 Star: Reached house without extra collectibles
    return 1;
  }
}
