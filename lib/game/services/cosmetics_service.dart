class CosmeticItem {
  final String id;
  final String name;
  final String category; // 'mouse', 'cat', 'house'
  final int costInCheese;
  final String previewEmoji;
  final String description;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.category,
    required this.costInCheese,
    required this.previewEmoji,
    required this.description,
  });
}

class CosmeticsService {
  static final CosmeticsService _instance = CosmeticsService._internal();
  factory CosmeticsService() => _instance;
  CosmeticsService._internal();

  // Equipped item IDs
  String equippedMouseId = 'mouse_classic';
  String equippedCatId = 'cat_tabby';
  String equippedHouseId = 'house_cottage';

  // Unlocked item IDs
  final Set<String> unlockedIds = {
    'mouse_classic',
    'cat_tabby',
    'house_cottage',
  };

  static const List<CosmeticItem> allItems = [
    // Mouse Skins
    CosmeticItem(
      id: 'mouse_classic',
      name: 'Classic Grey',
      category: 'mouse',
      costInCheese: 0,
      previewEmoji: '🐭',
      description: 'The agile, classic grey mouse.',
    ),
    CosmeticItem(
      id: 'mouse_golden',
      name: 'Golden Champion',
      category: 'mouse',
      costInCheese: 15,
      previewEmoji: '✨',
      description: 'Radiant golden fur with sparkling trails.',
    ),
    CosmeticItem(
      id: 'mouse_ninja',
      name: 'Shadow Ninja',
      category: 'mouse',
      costInCheese: 25,
      previewEmoji: '🥷',
      description: 'Stealth dark suit and crimson headband.',
    ),
    CosmeticItem(
      id: 'mouse_cyber',
      name: 'Cyberpunk Neon',
      category: 'mouse',
      costInCheese: 40,
      previewEmoji: '🤖',
      description: 'Futuristic glowing visor and cyber armor.',
    ),

    // Cat Styles
    CosmeticItem(
      id: 'cat_tabby',
      name: 'Orange Tabby',
      category: 'cat',
      costInCheese: 0,
      previewEmoji: '🐱',
      description: 'Classic watchful ginger tabby cat.',
    ),
    CosmeticItem(
      id: 'cat_shadow',
      name: 'Midnight Panther',
      category: 'cat',
      costInCheese: 20,
      previewEmoji: '🐈‍⬛',
      description: 'Sleek black coat with glowing amber gaze.',
    ),
    CosmeticItem(
      id: 'cat_robo',
      name: 'Mecha Sentry',
      category: 'cat',
      costInCheese: 35,
      previewEmoji: '🦾',
      description: 'High-tech surveillance robotic feline.',
    ),

    // House Styles
    CosmeticItem(
      id: 'house_cottage',
      name: 'Red Cottage',
      category: 'house',
      costInCheese: 0,
      previewEmoji: '🏠',
      description: 'Warm cozy cottage with red gable roof.',
    ),
    CosmeticItem(
      id: 'house_cheese',
      name: 'Cheese Palace',
      category: 'house',
      costInCheese: 25,
      previewEmoji: '🧀',
      description: 'Grand royal palace sculpted from aged cheddar.',
    ),
    CosmeticItem(
      id: 'house_scifi',
      name: 'Bio Dome Haven',
      category: 'house',
      costInCheese: 40,
      previewEmoji: '🛸',
      description: 'Pressurized safety dome with cyan neon aura.',
    ),
  ];

  bool isUnlocked(String id) => unlockedIds.contains(id);

  bool buyItem(CosmeticItem item, int currentCheese, bool Function(int) deductCheese) {
    if (isUnlocked(item.id)) {
      equipItem(item);
      return true;
    }
    if (currentCheese >= item.costInCheese) {
      if (!deductCheese(item.costInCheese)) return false;
      unlockedIds.add(item.id);
      equipItem(item);
      return true;
    }
    return false;
  }

  void equipItem(CosmeticItem item) {
    if (!isUnlocked(item.id)) return;
    switch (item.category) {
      case 'mouse':
        equippedMouseId = item.id;
        break;
      case 'cat':
        equippedCatId = item.id;
        break;
      case 'house':
        equippedHouseId = item.id;
        break;
    }
  }
}
