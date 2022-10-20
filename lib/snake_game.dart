import 'dart:math';

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
  static const foodRadius = 5.0;
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

  void generateFood() {
    final emptyCells = _cells
        .expand((element) => element)
        .where((element) => element.cellType == CellType.empty)
        .toList();
    emptyCells[Random().nextInt(emptyCells.length)].cellType = CellType.food;
  }
}

enum CellType { empty, snakeBody, food }

class Cell extends PositionComponent with HasGameRef<SnakeGame> {
  Cell(this.pos, {this.cellType = CellType.empty})
      : assert(_renderers[CellType.empty.index] is EmptyCellRenderer),
        assert(_renderers[CellType.snakeBody.index] is SnakeBodyRenderer),
        assert(_renderers[CellType.food.index] is FoodRenderer);

  static final _renderers = <CellRenderer>[
    EmptyCellRenderer(),
    SnakeBodyRenderer(),
    FoodRenderer(),
  ];

  final CellPos pos; // position in columns and rows
  late final Vector2 loc; // top-left of cell in pixels
  CellType cellType; // changes as the snake moves around

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    loc = Vector2(
      (pos.col * GameConfig.cellWidth).toDouble(),
      (pos.row * GameConfig.cellHeight).toDouble(),
    );
  }

  @override
  void render(Canvas canvas) => _renderers[cellType.index].render(canvas, loc);
}

abstract class CellRenderer {
  void render(Canvas canvas, Vector2 loc);
}

class EmptyCellRenderer extends CellRenderer {
  @override
  void render(Canvas canvas, Vector2 loc) {}
}

class SnakeBodyRenderer extends CellRenderer {
  @override
  void render(Canvas canvas, Vector2 loc) => canvas.drawRect(
        Rect.fromPoints(getStart(loc), getEnd(loc)),
        Styles.snakeBody,
      );

  static Offset getStart(Vector2 loc) => Offset(
        loc.x + GameConfig.snakeLineThickness / 2,
        loc.y + GameConfig.snakeLineThickness / 2,
      );

  static Offset getEnd(Vector2 loc) => Offset(
        loc.x + GameConfig.cellWidth - GameConfig.snakeLineThickness / 2,
        loc.y + GameConfig.cellHeight - GameConfig.snakeLineThickness / 2,
      );
}

class FoodRenderer extends CellRenderer {
  @override
  void render(Canvas canvas, Vector2 loc) {
    canvas.drawOval(
      Rect.fromLTWH(
        loc.x,
        loc.y,
        GameConfig.cellWidth.toDouble(),
        GameConfig.cellHeight.toDouble(),
      ),
      Styles.red,
    );
  }
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

class GameArea extends Component {
  GameArea() {
    // initialize snake
    const headIndex = GameConfig.headIndex;
    const snakeLength = GameConfig.initialSnakeLength;

    for (var i = 0; i < snakeLength; i++) {
      final cell = grid.findCell(CellPos(headIndex.row - i, headIndex.col));
      snake.addLast(cell);
    }

    // put out some food
    grid.generateFood();
  }

  final background = Background();
  final grid = Grid(GameConfig.rows, GameConfig.cols);
  final snake = Snake();

  @override
  Future<void>? onLoad() async {
    await super.onLoad();

    await add(background);

    for (final rows in grid.cells) {
      for (final cell in rows) {
        await add(cell);
      }
    }
  }
}

class SnakeGame extends FlameGame {
  final area = GameArea();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // assuming that Flutter is doing the centering and scaling,
    // then the grid and the canvas should be the same size
    assert(canvasSize.x == GameConfig.gridWidth);
    assert(canvasSize.y == GameConfig.gridHeight);

    await add(area);
  }
}

class Background extends PositionComponent with HasGameRef<SnakeGame> {
  @override
  void render(Canvas canvas) {
    final size = gameRef.canvasSize;
    canvas.drawRect(
      size.toRect(),
      Paint()..color = Colors.white,
    );

    _drawVerticalLines(canvas, size);
    _drawHorizontalLines(canvas, size);
  }

  void _drawVerticalLines(Canvas canvas, Vector2 size) {
    for (var x = 0.0; x <= size.x; x += GameConfig.cellWidth) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.y),
        Paint()..color = Colors.blue,
      );
    }
  }

  void _drawHorizontalLines(Canvas canvas, Vector2 size) {
    for (var y = 0.0; y <= size.y; y += GameConfig.cellHeight) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        Paint()..color = Colors.blue,
      );
    }
  }
}
