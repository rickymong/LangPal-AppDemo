// ignore_for_file: prefer_final_fields, file_names

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/colors.dart';
import 'package:langpal_prototype/games/wordle/data/word_list.dart';
import 'package:langpal_prototype/games/wordle/widgets/board.dart';
import 'package:langpal_prototype/games/wordle/widgets/keyboard.dart';
import 'package:provider/provider.dart';
import '../models/letterModel.dart';
import '../models/wordModel.dart';

//https://www.youtube.com/watch?v=_W0RN_Cqhpg&t=341s - source of design
///Tasklist:
/// [] create API service class
/// [] before evaluating the users entry, first check if it is a valid word
/// [] dispose the post game snackbar before leaving the screen
/// [] add hints?



enum GameStatus { playing, submitting, lost, won }

class WordleScreen extends StatefulWidget {
  const WordleScreen({Key? key}) : super(key: key);

  _WordleScreenState createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  GameStatus _gameStatus = GameStatus.playing;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<Word> _board = List.generate(
      6,
      (_) => Word(
          letters: List.generate(
              5,
              (_) => Letter
                  .empty()))); //generate the board (6 tries) 5 letters long

  int _currentWordIndex = 0;
  Word? get _currentWord =>
      _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;
  @override
  void initState(){
    super.initState();
    //call API
  }
  //SET API SOLUTION WORD HERE
  Word _solution = Word.fromString(
    fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
  );

  final Set<Letter> _keyboardLetters = {};

  @override
  void dispose() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('WORDLE')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Board(board: _board),
            SizedBox(height: height * 0.1), //set value of 80
            Keyboard(
                onKeyTapped: _onKeyTapped,
                onDeleteTapped: _onDeleteTapped,
                onEnterTapped: _onEnterTapped,
                letters: _keyboardLetters),
          ],
        ),
      ),
    );
  }

  void _onKeyTapped(String val) {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.addLetter(val));
    }
  }

  void _onDeleteTapped() {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.removeLetter());
    }
  }

  void _onEnterTapped() {
    print("in onEnterTapped");
    if (_gameStatus == GameStatus.playing &&
        _currentWord != null &&
        !_currentWord!.letters.contains(Letter.empty())) {
      _gameStatus = GameStatus.submitting;

      for (var i = 0; i < _currentWord!.letters.length; i++) {
        final currentWordLetter = _currentWord!.letters[i];
        final currentSolutionLetter = _solution.letters[i];
        print(
            "setting state: currentLetter $currentWordLetter, solutionLetter: $currentSolutionLetter");
        setState(() {
          if (currentWordLetter == currentSolutionLetter) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.correct);
          } else if (_solution.letters.contains(currentWordLetter)) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.inWord);
          } else {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.notInWord);
          }
        });

        final letter = _keyboardLetters.firstWhere(
            (e) => e.val == currentWordLetter.val,
            orElse: () => Letter.empty());
        if (letter.status != LetterStatus.correct) {
          _keyboardLetters.removeWhere((e) => e.val == currentWordLetter.val);
          _keyboardLetters.add(_currentWord!.letters[i]);
        }
      }
      print("calling check if win or loss");
      _checkIfWinOrLoss();
    }
    print("exiting on enter tapped");
  }

  void _checkIfWinOrLoss() {
    if (_currentWord!.wordString == _solution.wordString) {
      _gameStatus = GameStatus.won;
     _messengerKey.currentState?.showSnackBar(SnackBar(
        dismissDirection: DismissDirection.horizontal,
        duration: Duration(days: 1),
        backgroundColor: correctColor,
        content: const Text(
          "You Won!",
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          textColor: Colors.white,
          label: "New Game",
          onPressed: _restart,
        ),
      ));
    } else if (_currentWordIndex + 1 >= _board.length) {
      _gameStatus = GameStatus.lost;
      _messengerKey.currentState?.showSnackBar(SnackBar(
        dismissDirection: DismissDirection.horizontal,
        duration: Duration(days: 1),
        backgroundColor: Colors.redAccent[200],
        content: Text(
          'You Lost! Solution: ${_solution.wordString}',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          textColor: Colors.white,
          label: "New Game",
          onPressed: _restart,
        ),
      ));
    } else {
      _gameStatus = GameStatus.playing;
    }
    _currentWordIndex += 1;
    print("Current word index: ${_currentWordIndex}");
  }

  void _restart() {
    setState(() {
      _gameStatus = GameStatus.playing;
      _currentWordIndex = 0;
      _board
        ..clear()
        ..addAll(List.generate(
            6, (_) => Word(letters: List.generate(5, (_) => Letter.empty()))));
      _solution = Word.fromString(
          fiveLetterWords[Random().nextInt(fiveLetterWords.length)]
              .toUpperCase());
    });
    _keyboardLetters.clear();
  }
}
