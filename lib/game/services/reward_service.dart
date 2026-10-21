abstract class RewardService {
  Future<bool> showRewardedHint();
}

class MockRewardService implements RewardService {
  @override
  Future<bool> showRewardedHint() async {
    // Direct success for POC (future SDK hooks go here)
    return true;
  }
}
