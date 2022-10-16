// Flame Snake:
//  https://blog.devgenius.io/lets-create-a-snake-game-using-flutter-and-flame-38482d3cf0ff
//
// Apple ][ Snake Byte:
//  https://www.youtube.com/watch?v=sZ1fBpcLCYE
//  https://en.wikipedia.org/wiki/Snake_Byte
//
// Flame:
//  https://flame-engine.org/
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
