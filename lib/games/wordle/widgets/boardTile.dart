import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/models/letterModel.dart';
import 'package:langpal_prototype/games/wordle/widgets/board.dart';

class BoardTile extends StatelessWidget {
  const BoardTile({Key? key, required this.letter}) : super(key: key);

  final Letter letter;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.all(4),
      height: height * 0.1,
      width: width * 0.1,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: letter.backgroundColor,
          border: Border.all(color: letter.borderColor),
          borderRadius: BorderRadius.circular(4)),
      child: Text(letter.val,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }
}
