import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final List<Color> bgGradient;
  final Color wallTop;
  final Color wallBottom;
  final Color wallHighlight;
  final Color floorBase;
  final Color floorSeam;
  final Color treeFoliageDark;
  final Color treeFoliageMid;
  final Color lanternGlow;
  final Color lanternGlass;

  const ThemeConfig({
    required this.name,
    required this.bgGradient,
    required this.wallTop,
    required this.wallBottom,
    required this.wallHighlight,
    required this.floorBase,
    required this.floorSeam,
    required this.treeFoliageDark,
    required this.treeFoliageMid,
    required this.lanternGlow,
    required this.lanternGlass,
  });

  /// Theme 1 (Easy / Levels 1–2): Whispering Forest (Cool Navy, Slate Stone, Lush Pine, Amber Lanterns)
  static const ThemeConfig forest = ThemeConfig(
    name: 'Whispering Forest',
    bgGradient: [Color(0xFF1B243B), Color(0xFF0C101C), Color(0xFF060911)],
    wallTop: Color(0xFF5D6B88),
    wallBottom: Color(0xFF384357),
    wallHighlight: Color(0xFF8898B8),
    floorBase: Color(0xFF1E2436),
    floorSeam: Color(0xFF161B2A),
    treeFoliageDark: Color(0xFF0F261D),
    treeFoliageMid: Color(0xFF16382B),
    lanternGlow: Color(0xFFFFB300),
    lanternGlass: Color(0xFFFFF275),
  );

  /// Theme 2 (Medium / Levels 3–4): Golden Autumn / Sunset Dunes (Warm Twilight, Sandstone, Terracotta)
  static const ThemeConfig autumn = ThemeConfig(
    name: 'Autumn Sunset',
    bgGradient: [Color(0xFF2E1738), Color(0xFF1A0E24), Color(0xFF0D0614)],
    wallTop: Color(0xFF8C624A),
    wallBottom: Color(0xFF5A3926),
    wallHighlight: Color(0xFFB88C72),
    floorBase: Color(0xFF2E202A),
    floorSeam: Color(0xFF22151E),
    treeFoliageDark: Color(0xFF3E1E12),
    treeFoliageMid: Color(0xFF6B301A),
    lanternGlow: Color(0xFFFF7043),
    lanternGlass: Color(0xFFFFD54F),
  );

  /// Theme 3 (Milestone & Hard / Level 5+): Crystal Dungeon / Obsidian Cavern (Amethyst, Cyan Neon)
  static const ThemeConfig crystalDungeon = ThemeConfig(
    name: 'Crystal Cavern',
    bgGradient: [Color(0xFF172038), Color(0xFF0E1326), Color(0xFF050712)],
    wallTop: Color(0xFF5E4B8A),
    wallBottom: Color(0xFF362657),
    wallHighlight: Color(0xFF9078C7),
    floorBase: Color(0xFF1B1830),
    floorSeam: Color(0xFF131024),
    treeFoliageDark: Color(0xFF112233),
    treeFoliageMid: Color(0xFF1B3D57),
    lanternGlow: Color(0xFF00E5FF),
    lanternGlass: Color(0xFFE0F7FA),
  );

  /// Theme 4 (Levels 31–40): Emerald Jungle (Deep emerald greens, vines, jade walls)
  static const ThemeConfig emeraldJungle = ThemeConfig(
    name: 'Emerald Jungle',
    bgGradient: [Color(0xFF0A2617), Color(0xFF04170D), Color(0xFF020B06)],
    wallTop: Color(0xFF2E7D4E),
    wallBottom: Color(0xFF1B4D30),
    wallHighlight: Color(0xFF52B788),
    floorBase: Color(0xFF163224),
    floorSeam: Color(0xFF0E2318),
    treeFoliageDark: Color(0xFF0A1F14),
    treeFoliageMid: Color(0xFF123D26),
    lanternGlow: Color(0xFF2EC4B6),
    lanternGlass: Color(0xFFCBF3F0),
  );

  /// Theme 5 (Levels 41–50): Frozen Glacier (Cyan ice, glacial blue stone, crisp snow highlights)
  static const ThemeConfig frozenGlacier = ThemeConfig(
    name: 'Frozen Glacier',
    bgGradient: [Color(0xFF0F2B48), Color(0xFF081829), Color(0xFF030A12)],
    wallTop: Color(0xFF4A90B8),
    wallBottom: Color(0xFF255778),
    wallHighlight: Color(0xFF90D5FF),
    floorBase: Color(0xFF162A3D),
    floorSeam: Color(0xFF0E1C2B),
    treeFoliageDark: Color(0xFF0E243A),
    treeFoliageMid: Color(0xFF1A456E),
    lanternGlow: Color(0xFF00E5FF),
    lanternGlass: Color(0xFFE1F5FE),
  );

  /// Theme 6 (Levels 51–60): Volcanic Forge (Obsidian black, molten crimson, ember orange)
  static const ThemeConfig volcanicForge = ThemeConfig(
    name: 'Volcanic Forge',
    bgGradient: [Color(0xFF381010), Color(0xFF210808), Color(0xFF0D0303)],
    wallTop: Color(0xFF8B2626),
    wallBottom: Color(0xFF4E1414),
    wallHighlight: Color(0xFFE55353),
    floorBase: Color(0xFF2C1616),
    floorSeam: Color(0xFF1C0D0D),
    treeFoliageDark: Color(0xFF2D0E0E),
    treeFoliageMid: Color(0xFF5A1E1E),
    lanternGlow: Color(0xFFFF5722),
    lanternGlass: Color(0xFFFFCCBC),
  );

  /// Theme 7 (Levels 61–70): Desert Ruins (Golden sandstone, Egyptian ochre, warm sunbeams)
  static const ThemeConfig desertRuins = ThemeConfig(
    name: 'Desert Ruins',
    bgGradient: [Color(0xFF332412), Color(0xFF1F150A), Color(0xFF0F0903)],
    wallTop: Color(0xFFB88A44),
    wallBottom: Color(0xFF7A5726),
    wallHighlight: Color(0xFFE5B56E),
    floorBase: Color(0xFF362817),
    floorSeam: Color(0xFF24190C),
    treeFoliageDark: Color(0xFF2E2211),
    treeFoliageMid: Color(0xFF5E431E),
    lanternGlow: Color(0xFFFFC107),
    lanternGlass: Color(0xFFFFF9C4),
  );

  /// Theme 8 (Levels 71–80): Neon Cyberpunk (Dark violet, hot pink highlights, electric cyan)
  static const ThemeConfig neonCyberpunk = ThemeConfig(
    name: 'Neon Cyberpunk',
    bgGradient: [Color(0xFF210E36), Color(0xFF11071F), Color(0xFF07020F)],
    wallTop: Color(0xFF7B2CBF),
    wallBottom: Color(0xFF48147A),
    wallHighlight: Color(0xFFC77DFF),
    floorBase: Color(0xFF241538),
    floorSeam: Color(0xFF160B24),
    treeFoliageDark: Color(0xFF1E0F33),
    treeFoliageMid: Color(0xFF401C6B),
    lanternGlow: Color(0xFFFF007F),
    lanternGlass: Color(0xFFFFC6FF),
  );

  /// Theme 9 (Levels 81–90): Ghostly Graveyard (Eerie misty blue-green, cursed purple glow)
  static const ThemeConfig ghostlyGraveyard = ThemeConfig(
    name: 'Ghostly Graveyard',
    bgGradient: [Color(0xFF0F1E24), Color(0xFF081217), Color(0xFF03070A)],
    wallTop: Color(0xFF40656E),
    wallBottom: Color(0xFF233B42),
    wallHighlight: Color(0xFF6E9DA8),
    floorBase: Color(0xFF16252B),
    floorSeam: Color(0xFF0D171C),
    treeFoliageDark: Color(0xFF0B191F),
    treeFoliageMid: Color(0xFF16323D),
    lanternGlow: Color(0xFF00FF9D),
    lanternGlass: Color(0xFFB9FBC0),
  );

  /// Theme 10 (Levels 91–100): Celestial Citadel (Deep cosmic indigo, starlight gold, royal velvet)
  static const ThemeConfig celestialCitadel = ThemeConfig(
    name: 'Celestial Citadel',
    bgGradient: [Color(0xFF1A153B), Color(0xFF0F0B24), Color(0xFF060412)],
    wallTop: Color(0xFF5A48A3),
    wallBottom: Color(0xFF35276B),
    wallHighlight: Color(0xFF9180E2),
    floorBase: Color(0xFF211B42),
    floorSeam: Color(0xFF140F2C),
    treeFoliageDark: Color(0xFF161236),
    treeFoliageMid: Color(0xFF2E2466),
    lanternGlow: Color(0xFFFFD700),
    lanternGlass: Color(0xFFFFF8DC),
  );

  static ThemeConfig forLevel(int level) {
    final world = ((level - 1) ~/ 10) + 1;
    switch (world) {
      case 1:
        return forest;
      case 2:
        return autumn;
      case 3:
        return crystalDungeon;
      case 4:
        return emeraldJungle;
      case 5:
        return frozenGlacier;
      case 6:
        return volcanicForge;
      case 7:
        return desertRuins;
      case 8:
        return neonCyberpunk;
      case 9:
        return ghostlyGraveyard;
      case 10:
      default:
        return celestialCitadel;
    }
  }
}
