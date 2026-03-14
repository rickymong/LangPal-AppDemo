import 'dart:math';

import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/data/word_list.dart';
import 'package:langpal_prototype/games/wordle/widgets/board.dart';
import 'package:langpal_prototype/games/wordle/widgets/keyboard.dart';
import '../models/letterModel.dart';
import '../models/wordModel.dart';

enum GameStatus { playing, submitting, lost, won }

class WordleScreen extends StatefulWidget {
  const WordleScreen({Key? key}) : super(key: key);

  _WordleScreenState createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  GameStatus _gameStatus = GameStatus.playing;
  final List<Word> _board = List.generate(
      6,
      (_) => Word(
          letters: List.generate(
              5,
              (_) => Letter
                  .empty()))); //generate the board (6 tries) 5 letters long

  int _currentWordIndex = 0;
  Word? get currentWord =>
      _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;
  Word _solution = Word.fromString(
    fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
  );

  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('WORDLE')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Board(board: _board),
          SizedBox(height: height * 0.2), //set value of 80
          Keyboard(
              onKeyTapped: _onKeyTapped,
              onDeleteTapped: _onDeleteTapped,
              onEnterTapped: _onEnterTapped)
        ],
      ),
    );
  }
}
