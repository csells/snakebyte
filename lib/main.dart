import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'snake_game.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  child: SizedBox(
                    width: GameConfig.gridWidth.toDouble(),
                    height: GameConfig.gridHeight.toDouble(),
                    child: GameWidget(game: SnakeGame()),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
