import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart' show Colors, Paint, PaintingStyle;

class CellPos {
  const CellPos(this.row, this.col);

  final int row;
  final int col;
}

class GameConfig {
  static const rows = 36;
  static const cols = 39;
  static const cellWidth = 47;
  static const cellHeight = 29;
  static const gridWidth = cols * cellWidth;
  static const gridHeight = rows * cellHeight;
  static const initialSnakeLength = 3;
  static const headIndex = CellPos(
    rows - 1,
    20, // == cols/2
  );
  // static const fps = 5.0;
  // static const foodRadius = 5.0;
  static const snakeLineThickness = 1.0;
}

class Styles {
  static Paint white = BasicPalette.white.paint();
  static Paint blue = BasicPalette.blue.paint();
  static Paint red = BasicPalette.red.paint();

  static Paint snakeBody = BasicPalette.black.paint()
    ..style = PaintingStyle.fill
    ..strokeWidth = GameConfig.snakeLineThickness;

  static Paint gameOver = BasicPalette.red.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
}

class Grid {
  Grid(this.rows, this.cols) {
    _cells = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => Cell(CellPos(r, c)),
      ),
    );
  }

  static Cell border = Cell(const CellPos(-1, -1));

  final int rows;
  final int cols;
  late final List<List<Cell>> _cells;

  List<List<Cell>> get cells => _cells;

  Cell findCell(CellPos pos) =>
      (pos.col < 0 || pos.col >= cols || pos.row < 0 || pos.row >= rows)
          ? border
          : _cells[pos.row][pos.col];
}

enum CellType { empty, snakeBody }

class Cell extends PositionComponent with HasGameRef<SnakeGame> {
  Cell(this.pos, {this.cellType = CellType.empty});

  final CellPos pos; // position in columns and rows
  late final Vector2 loc; // top-left of cell in pixels
  CellType cellType; // changes as the snake moves around

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final start = gameRef.offSets.start;
    loc = Vector2(
      pos.col * GameConfig.cellWidth + start.x,
      pos.row * GameConfig.cellHeight + start.y,
    );
  }

  @override
  void render(Canvas canvas) {
    switch (cellType) {
      case CellType.snakeBody:
        SnakeBody.render(canvas, loc);
        break;
      case CellType.empty:
        break;
    }
  }
}

class SnakeBody {
  static void render(Canvas canvas, Vector2 loc) => canvas.drawRect(
        Rect.fromPoints(findStart(loc), findEnd(loc)),
        Styles.snakeBody,
      );

  static Offset findStart(Vector2 loc) => Offset(
        loc.x + GameConfig.snakeLineThickness / 2,
        loc.y + GameConfig.snakeLineThickness / 2,
      );

  static Offset findEnd(Vector2 loc) => Offset(
        loc.x + GameConfig.cellWidth - GameConfig.snakeLineThickness / 2,
        loc.y + GameConfig.cellHeight - GameConfig.snakeLineThickness / 2,
      );
}

class Snake {
  final _snakeBody = List<Cell>.empty(growable: true);

  // snake grows
  void addLast(Cell cell) {
    cell.cellType = CellType.snakeBody;
    _snakeBody.add(cell);
  }

  // snake moves
  void removeLast() {
    _snakeBody.last.cellType = CellType.empty;
    _snakeBody.remove(_snakeBody.last);
  }
}

class World extends Component {
  World(this.grid) {
    _initializeSnake();
  }

  final Grid grid;
  final Snake snake = Snake();

  void _initializeSnake() {
    const headIndex = GameConfig.headIndex;
    const snakeLength = GameConfig.initialSnakeLength;

    for (var i = 0; i < snakeLength; i++) {
      final cell = grid.findCell(CellPos(headIndex.row - i, headIndex.col));
      snake.addLast(cell);
    }
  }
}

class SnakeGame extends FlameGame {
  final world = World(Grid(GameConfig.rows, GameConfig.cols));
  late final Offsets offSets;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    offSets = Offsets(canvasSize);

    await add(Background());
    await add(world);

    final grid = world.grid;
    for (final rows in grid.cells) {
      for (final cell in rows) {
        await add(cell);
      }
    }
  }
}

class Offsets {
  Offsets(Vector2 canvasSize) {
    start = Vector2(
      (canvasSize.x - GameConfig.gridWidth) / 2,
      (canvasSize.y - GameConfig.gridHeight) / 2,
    );

    end = Vector2(
      canvasSize.x - start.x,
      canvasSize.y - start.y,
    );
  }
  // grid’s starting and ending coordinates on the game's canvas in pixels
  late final Vector2 start;
  late final Vector2 end;
}

class Background extends PositionComponent with HasGameRef<SnakeGame> {
  late final Offset start;
  late final Offset end;

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
    for (var x = start.dx; x <= end.dx; x += GameConfig.cellWidth) {
      c.drawLine(
        Offset(x, start.dy),
        Offset(x, end.dy),
        Paint()..color = Colors.blue,
      );
    }
  }

  void _drawHorizontalLines(Canvas c) {
    for (var y = start.dy; y <= end.dy; y += GameConfig.cellHeight) {
      c.drawLine(
        Offset(start.dx, y),
        Offset(end.dx, y),
        Paint()..color = Colors.blue,
      );
    }
  }
}
