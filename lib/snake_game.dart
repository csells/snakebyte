import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors, Paint;

class GameConfig {
  static const rows = 36;
  static const columns = 39;
  static const cellWidth = 47;
  static const cellHeight = 29;
  static const gridWidth = columns * cellWidth;
  static const gridHeight = rows * cellHeight;
}

class SnakeGame extends FlameGame {
  late final OffSets offSets;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    offSets = OffSets(canvasSize);
    await add(BackGround(
      cellWidth: GameConfig.cellWidth,
      cellHeight: GameConfig.cellHeight,
    ));
  }
}

class OffSets {
  OffSets(Vector2 canvasSize) {
    start = Vector2(
      (canvasSize.x - GameConfig.gridWidth) / 2,
      (canvasSize.y - GameConfig.gridHeight) / 2,
    );

    end = Vector2(
      canvasSize.x - start.x,
      canvasSize.y - start.y,
    );
  }
  // grid’s starting and ending coordinates
  late final Vector2 start;
  late final Vector2 end;
}

class BackGround extends PositionComponent with HasGameRef<SnakeGame> {
  BackGround({required this.cellWidth, required this.cellHeight});
  late final Offset start;
  late final Offset end;

  final int cellWidth;
  final int cellHeight;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    start = gameRef.offSets.start.toOffset();
    end = gameRef.offSets.end.toOffset();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromPoints(start, end),
      Paint()..color = Colors.white,
    );
    _drawVerticalLines(canvas);
    _drawHorizontalLines(canvas);
  }

  void _drawVerticalLines(Canvas c) {
    for (var x = start.dx; x <= end.dx; x += cellWidth) {
      c.drawLine(
        Offset(x, start.dy),
        Offset(x, end.dy),
        Paint()..color = Colors.blue,
      );
    }
  }

  void _drawHorizontalLines(Canvas c) {
    for (var y = start.dy; y <= end.dy; y += cellHeight) {
      c.drawLine(
        Offset(start.dx, y),
        Offset(end.dx, y),
        Paint()..color = Colors.blue,
      );
    }
  }
}
