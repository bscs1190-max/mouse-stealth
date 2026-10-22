import 'package:flutter/material.dart';

import '../game/services/cosmetics_service.dart';
import '../game/services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/game_ui.dart';
import '../ui/widgets/outlined_text.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final cosmetics = CosmeticsService();
  final progress = ProgressService();
  String _category = 'mouse';

  static const _tabs = [('mouse', 'Mice', '🐭'), ('cat', 'Cats', '🐱'), ('house', 'Houses', '🏠')];

  bool _isEquipped(CosmeticItem item) =>
      (item.category == 'mouse' && cosmetics.equippedMouseId == item.id) ||
      (item.category == 'cat' && cosmetics.equippedCatId == item.id) ||
      (item.category == 'house' && cosmetics.equippedHouseId == item.id);

  void _onItemTap(CosmeticItem item) {
    if (cosmetics.isUnlocked(item.id)) {
      setState(() => cosmetics.equipItem(item));
      return;
    }
    final ok = cosmetics.buyItem(item, progress.totalCheeseCurrency, progress.deductCheese);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '🎉 ${item.name} unlocked & equipped!'
              : 'You need ${item.costInCheese - progress.totalCheeseCurrency} more 🧀',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CosmeticsService.allItems.where((i) => i.category == _category).toList();

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(alignment: Alignment.centerLeft, child: OutlinedText('Cheese Shop', size: 28)),
                    ),
                    CheeseCounter(amount: progress.totalCheeseCurrency),
                  ],
                ),
              ),

              // Segmented category selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      for (final t in _tabs)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _category = t.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: _category == t.$1
                                    ? const LinearGradient(colors: [AppColors.cheese, AppColors.cheeseDeep])
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(t.$3, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.$2,
                                    style: AppText.title(
                                      15,
                                      color: _category == t.$1 ? AppColors.bgBottom : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _ItemCard(
                    item: items[i],
                    unlocked: cosmetics.isUnlocked(items[i].id),
                    equipped: _isEquipped(items[i]),
                    affordable: progress.totalCheeseCurrency >= items[i].costInCheese,
                    onTap: () => _onItemTap(items[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CosmeticItem item;
  final bool unlocked;
  final bool equipped;
  final bool affordable;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.unlocked,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = equipped ? AppColors.mint : (unlocked ? AppColors.violet : AppColors.cheese);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: equipped ? AppColors.mint : AppColors.outline, width: equipped ? 2.5 : 1.5),
        boxShadow: [
          if (equipped) BoxShadow(color: AppColors.mint.withValues(alpha: 0.35), blurRadius: 18),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.35), AppColors.bgBottom.withValues(alpha: 0.6)],
                ),
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: unlocked ? 1 : 0.75,
                child: Text(item.previewEmoji, style: const TextStyle(fontSize: 46)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title(16)),
          const SizedBox(height: 2),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(11.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: 10),
          if (equipped)
            Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                  const SizedBox(width: 6),
                  Text('EQUIPPED', style: AppText.title(13, color: AppColors.mint)),
                ],
              ),
            )
          else if (unlocked)
            ChunkyButton(
              label: 'EQUIP',
              color: AppColors.violetDeep,
              shadeColor: const Color(0xFF3A2AA8),
              height: 40,
              fontSize: 14,
              onPressed: onTap,
            )
          else
            ChunkyButton(
              label: '${item.costInCheese}',
              leading: const Text('🧀', style: TextStyle(fontSize: 16)),
              color: affordable ? AppColors.cheeseDeep : AppColors.surfaceHigh,
              shadeColor: affordable ? const Color(0xFFA35400) : AppColors.outline,
              height: 40,
              fontSize: 15,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
