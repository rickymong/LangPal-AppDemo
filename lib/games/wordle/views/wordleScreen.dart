import 'dart:math';

import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/data/word_list.dart';
import '../models/letterModel.dart';
import '../models/wordModel.dart';


enum GameStatus {playing, submitting, lost, won}

class WordleScreen extends StatefulWidget{
  const WordleScreen({Key? key}) : super(key:key);

  _WordleScreenState createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen>{

  GameStatus _gameStatus = GameStatus.playing;
  final List<Word> _board = List.generate(6, (_) => 
    Word(letters: List.generate(5, (_) => Letter.empty()))); //generate the board (6 tries) 5 letters long

  int _currentWordIndex = 0;
  Word? get currentWord => _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;
  Word _solution = Word.fromString(fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),);
  
  Widget build(BuildContext context){


    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WORDLE'
        )
      ),
    )
  }
}