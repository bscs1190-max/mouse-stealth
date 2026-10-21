import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class LoadedLevelData {
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> walkableGrid;
  final Vector2 mouseSpawn;
  final Vector2 housePosition;
  final List<Vector2> cheesePositions;

  LoadedLevelData({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.walkableGrid,
    required this.mouseSpawn,
    required this.housePosition,
    required this.cheesePositions,
  });
}

class LevelLoader {
  static Future<LoadedLevelData> loadLevel(String tmxPath) async {
    final tiledMap = await TiledComponent.load(
      tmxPath,
      Vector2.all(32),
      prefix: 'assets/tiles/',
    );

    final tileMap = tiledMap.tileMap.map;
    final mapWidth = tileMap.width;
    final mapHeight = tileMap.height;
    final tileSize = tileMap.tileWidth.toDouble();

    // Parse layers
    final tileLayer = tiledMap.tileMap.getLayer<TileLayer>('Tile Layer 1');
    final walkableGrid = List.generate(
      mapHeight,
      (y) => List.generate(mapWidth, (x) => false),
    );

    if (tileLayer != null) {
      final data = tileLayer.data;
      if (data != null) {
        for (int y = 0; y < mapHeight; y++) {
          for (int x = 0; x < mapWidth; x++) {
            final tileGid = data[y * mapWidth + x];
            // In our tileset: GID 1 = Floor (walkable), GID 2 = Wall (unwalkable)
            walkableGrid[y][x] = (tileGid == 1);
          }
        }
      }
    }

    // Default positions in case objects are missing
    Vector2 mouseSpawn = Vector2(tileSize * 1.5, tileSize * 1.5);
    Vector2 housePosition = Vector2(tileSize * (mapWidth - 1.5), tileSize * (mapHeight - 1.5));
    final List<Vector2> cheesePositions = [];

    final objectGroup = tiledMap.tileMap.getLayer<ObjectGroup>('Objects');
    if (objectGroup != null) {
      for (final obj in objectGroup.objects) {
        final pos = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2);
        if (obj.type == 'MouseStart' || obj.name == 'MouseStart') {
          mouseSpawn = pos;
        } else if (obj.type == 'MouseHouse' || obj.name == 'MouseHouse') {
          housePosition = pos;
        } else if (obj.type == 'Cheese' || obj.name.startsWith('Cheese')) {
          cheesePositions.add(pos);
        }
      }
    }

    return LoadedLevelData(
      mapWidth: mapWidth,
      mapHeight: mapHeight,
      tileSize: tileSize,
      walkableGrid: walkableGrid,
      mouseSpawn: mouseSpawn,
      housePosition: housePosition,
      cheesePositions: cheesePositions,
    );
  }
}
