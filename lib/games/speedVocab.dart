import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../userNotifier.dart';

class SpeedVocab extends StatefulWidget {
  const SpeedVocab({super.key, required this.xp});

  final int xp;

  @override
  State<SpeedVocab> createState() => _SpeedVocabState();
}

class _SpeedVocabState extends State<SpeedVocab> {
  static const int _roundDurationSeconds = 45;
  static const int _questionsPerRound = 8;

  final Random _random = Random();
  Timer? _timer;

  int _timeLeft = _roundDurationSeconds;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  bool _isFinished = false;

  late final List<_SpeedQuestion> _questions;

  static const Map<String, String> _vocabBank = {
    'hola': 'hello',
    'adios': 'goodbye',
    'gracias': 'thank you',
    'por favor': 'please',
    'agua': 'water',
    'comida': 'food',
    'casa': 'house',
    'escuela': 'school',
    'libro': 'book',
    'amigo': 'friend',
    'familia': 'family',
    'trabajo': 'work',
  };

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isFinished) return;

      if (_timeLeft <= 1) {
        setState(() {
          _timeLeft = 0;
        });
        _finishGame();
        return;
      }

      setState(() {
        _timeLeft -= 1;
      });
    });
  }

  List<_SpeedQuestion> _buildQuestions() {
    final entries = _vocabBank.entries.toList()..shuffle(_random);
    final selected = entries.take(_questionsPerRound).toList();
    final allEnglish = _vocabBank.values.toList();

    return selected.map((entry) {
      final wrongAnswers = allEnglish
          .where((value) => value != entry.value)
          .toList()
        ..shuffle(_random);

      final options = <String>[entry.value, ...wrongAnswers.take(3)]..shuffle(_random);

      return _SpeedQuestion(
        prompt: entry.key,
        correctAnswer: entry.value,
        options: options,
      );
    }).toList();
  }

  void _selectAnswer(String answer) {
    if (_isFinished) return;

    final currentQuestion = _questions[_questionIndex];
    if (answer == currentQuestion.correctAnswer) {
      _correctAnswers += 1;
    }

    if (_questionIndex >= _questions.length - 1) {
      _finishGame();
      return;
    }

    setState(() {
      _questionIndex += 1;
    });
  }

  void _finishGame() {
    if (_isFinished) return;

    _isFinished = true;
    _timer?.cancel();

    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    final accuracy = _correctAnswers / _questions.length;

    // Reward full XP for strong performance, partial XP otherwise.
    final earnedXp = accuracy >= 0.7
        ? widget.xp
        : (accuracy >= 0.4 ? (widget.xp / 2).round() : 0);

    if (earnedXp > 0) {
      userNotifier.completeGame(earnedXp);
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Round Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $_correctAnswers / ${_questions.length}'),
              const SizedBox(height: 8),
              Text('XP Earned: $earnedXp'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final current = _questions[_questionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Speed Vocab',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Q ${_questionIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _timeLeft <= 10 ? const Color(0xFFFFE8E8) : const Color(0xFFF0F0F0),
                  ),
                  child: Text(
                    '$_timeLeft s',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _timeLeft <= 10 ? const Color(0xFFFF4B4B) : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Column(
                children: [
                  Text(
                    'What does this mean?',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...current.options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _selectAnswer(option),
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SpeedQuestion {
  const _SpeedQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final String correctAnswer;
  final List<String> options;
}