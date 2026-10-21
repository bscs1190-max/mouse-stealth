import 'package:flame/extensions.dart';

/// Pick-ups the mouse can collect from the floor.
enum PowerUpKind {
  /// Freezes every cat in place for a few seconds.
  freeze,

  /// Mouse runs much faster for a few seconds.
  speed,

  /// Cats cannot detect the mouse for a few seconds.
  ghost,
}

class PowerUpPlacement {
  final PowerUpKind kind;
  final Vector2 position;
  const PowerUpPlacement(this.kind, this.position);
}

extension PowerUpInfo on PowerUpKind {
  double get duration => switch (this) {
        PowerUpKind.freeze => 6.0,
        PowerUpKind.speed => 5.0,
        PowerUpKind.ghost => 6.0,
      };

  String get label => switch (this) {
        PowerUpKind.freeze => 'Cats frozen',
        PowerUpKind.speed => 'Speed boost',
        PowerUpKind.ghost => 'Invisible',
      };

  String get emoji => switch (this) {
        PowerUpKind.freeze => '❄️',
        PowerUpKind.speed => '⚡',
        PowerUpKind.ghost => '👻',
      };

  /// First level in which this power-up shows up.
  int get introducedAt => switch (this) {
        PowerUpKind.freeze => 2,
        PowerUpKind.speed => 11,
        PowerUpKind.ghost => 31,
      };
}
