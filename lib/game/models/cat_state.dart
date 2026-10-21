enum CatState {
  patrol, // Walking its fixed patrol route
  detect, // Mouse entered the radar: short reaction pause
  chase, // Following the mouse for a limited time
  returnToPatrol, // Lost the mouse: walking back onto its patrol route
}

class CatConfig {
  final String id;
  final List<List<int>> patrolWaypoints; // Grid [x, y] coordinates
  final double patrolSpeed;
  final double chaseSpeed;
  final double visionRange; // Radar radius in pixels
  final double visionFovDegrees; // 360.0 for full omnidirectional radar
  final double maxChaseSeconds; // How long the cat keeps following the mouse

  const CatConfig({
    required this.id,
    required this.patrolWaypoints,
    this.patrolSpeed = 65.0,
    this.chaseSpeed = 115.0,
    this.visionRange = 95.0,
    this.visionFovDegrees = 360.0,
    this.maxChaseSeconds = 3.0,
  });
}
