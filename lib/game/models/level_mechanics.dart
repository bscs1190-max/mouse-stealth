import 'package:flame/extensions.dart';

/// A barrier in a corridor that opens when the mouse presses a wall button.
class GatePlacement {
  /// Centre of the tile blocked by the gate.
  final Vector2 gate;

  /// Centre of the wall tile that carries the button (tap it to press).
  final Vector2 switchWall;

  /// Floor tile next to the button where the mouse stands to press it.
  final Vector2 pressSpot;

  const GatePlacement({required this.gate, required this.switchWall, required this.pressSpot});
}

/// Which extra mechanics a level uses.
class LevelMechanics {
  final bool lockedHouse;
  final bool gate;
  const LevelMechanics({this.lockedHouse = false, this.gate = false});

  /// First levels that use each mechanic (the intro card demonstrates them).
  static const int firstKeyLevel = 10;
  static const int firstGateLevel = 15;

  static LevelMechanics forLevel(int level, {required bool hard, required bool medium}) {
    if (hard) {
      // Rotates through: key, gate, both.
      switch ((level ~/ 10) % 3) {
        case 1:
          return const LevelMechanics(lockedHouse: true);
        case 2:
          return const LevelMechanics(gate: true);
        default:
          return const LevelMechanics(lockedHouse: true, gate: true);
      }
    }
    if (medium && level >= 15) return const LevelMechanics(gate: true);
    return const LevelMechanics();
  }
}
