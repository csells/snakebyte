import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart'
    show Colors, Paint, PaintingStyle, immutable;

@immutable
class CellPos {
  const CellPos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is CellPos && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode + col.hashCode;
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
  static const fps = 5.0;
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

enum Direction { N, S, E, W }

class Snake {
  final _snakeBody = List<Cell>.empty(growable: true);
  Direction direction = Direction.N;

  // snake grows
  void addLast(Cell cell) {
    cell.cellType = CellType.snakeBody;
    _snakeBody.add(cell);
  }

  // snake moves
  void move(Grid grid) {
    final headPos = _snakeBody.first.pos;
    late final CellPos newPos;
    switch (direction) {
      case Direction.N:
        newPos = CellPos(headPos.row - 1, headPos.col);
        break;
      case Direction.S:
        newPos = CellPos(headPos.row + 1, headPos.col);
        break;
      case Direction.E:
        newPos = CellPos(headPos.row, headPos.col + 1);
        break;
      case Direction.W:
        newPos = CellPos(headPos.row, headPos.col - 1);
        break;
    }

    final newCell = grid.findCell(newPos);
    if (newCell.loc == Grid.border.loc) return;

    _addFirst(newCell);
    _removeLast();
  }

  void _addFirst(Cell cell) {
    cell.cellType = CellType.snakeBody;
    _snakeBody.insert(0, cell);
  }

  void _removeLast() {
    _snakeBody.last.cellType = CellType.empty;
    _snakeBody.remove(_snakeBody.last);
  }

  Vector2 displacementToHead(Vector2 touchPoint) => Vector2(0, 0); // TODO
  bool isHorizontal() => false; // TODO
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

abstract class DynamicFpsPositionComponent extends PositionComponent {
  DynamicFpsPositionComponent() : _targetDt = 1 / GameConfig.fps;

  final double _targetDt;
  var _dtTotal = 0.0;

  @override
  void update(double dt) {
    super.update(dt);

    _dtTotal += dt;
    if (_dtTotal >= _targetDt) {
      _dtTotal = 0;
      updateDynamic(dt);
    }
  }

  void updateDynamic(double dt);
}

class CommandQueue {
  final touches = List<Vector2>.empty(growable: true);

  void add(Vector2 touchPoint) {
    if (touches.length != 3) touches.add(touchPoint);
  }

  void evaluateNextInput(Snake snake) {
    if (touches.isNotEmpty) {
      final touchPoint = touches[0];
      touches.remove(touchPoint);

      final delta = snake.displacementToHead(touchPoint);

      snake.direction = snake.isHorizontal()
          ? delta.y < 0
              ? Direction.N
              : Direction.S
          : delta.x < 0
              ? Direction.W
              : Direction.E;
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
