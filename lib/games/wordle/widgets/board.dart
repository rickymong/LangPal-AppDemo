import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/models/wordModel.dart';
import 'package:langpal_prototype/games/wordle/widgets/boardTile.dart';

class Board extends StatelessWidget {
  const Board({Key? key, required this.board}) : super(key: key);

  final List<Word> board;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: board
            .map((word) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: word.letters
                      .map((letter) => BoardTile(letter: letter))
                      .toList(),
                ))
            .toList());
  }
}
