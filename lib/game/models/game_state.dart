enum GameStatus {
  ready,
  drawing,
  pathInvalid,
  moving,
  success,
  gameOver,
  paused,
}

class GameSessionState {
  final int maxHearts;
  int hearts;
  int collectedCheese;
  final int totalCheese;
  GameStatus status;
  double? remainingTime;

  GameSessionState({
    this.maxHearts = 3,
    this.hearts = 3,
    this.collectedCheese = 0,
    this.totalCheese = 3,
    this.status = GameStatus.ready,
    this.remainingTime,
  });

  void reset() {
    hearts = maxHearts;
    collectedCheese = 0;
    status = GameStatus.ready;
  }
}
