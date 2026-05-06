import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../userNotifier.dart';
import '../services/speed_vocab_service.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// SpeedVocab – A timed vocabulary quiz mini-game.
///
/// Questions are fetched from the Gemini-powered FastAPI backend via
/// [SpeedVocabService] which calls `/games/matching/start`. The backend
/// generates vocab pairs personalized to the user's target language.
///
/// If the backend is unreachable, the game gracefully falls back to a
/// hardcoded Spanish vocab bank so the user can still play offline.
/// ──────────────────────────────────────────────────────────────────────────────
class SpeedVocab extends StatefulWidget {
  const SpeedVocab({super.key, required this.xp});

  final int xp;

  @override
  State<SpeedVocab> createState() => _SpeedVocabState();
}

class _SpeedVocabState extends State<SpeedVocab> {
  // ── Game Configuration ────────────────────────────────────────────────────
  static const int _roundDurationSeconds = 45;
  static const int _questionsPerRound = 8;

  final Random _random = Random();
  Timer? _timer;

  // ── Loading State ─────────────────────────────────────────────────────────
  /// Whether the game is still fetching vocab from the API.
  bool _isLoading = true;
  /// If the API call failed, this holds the error message for logging.
  String? _loadError;

  // ── Game Session State ────────────────────────────────────────────────────
  /// Remaining seconds in this round.
  int _timeLeft = _roundDurationSeconds;
  /// Index of the current question being displayed.
  int _questionIndex = 0;
  /// Running count of correct answers.
  int _correctAnswers = 0;
  /// `true` once the round is finished (timeout or all questions answered).
  bool _isFinished = false;
  /// Locks input while showing green/red color feedback on the options.
  bool _isRevealingFeedback = false;
  /// The option string the user last tapped.
  String? _selectedAnswer;

  /// Questions loaded for this round (either from API or fallback).
  List<_SpeedQuestion> _questions = [];

  // ── Hardcoded Fallback Vocab ──────────────────────────────────────────────
  /// Used when the backend is unreachable so the game can still be played.
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // Async – fetches from API then starts the game
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Question Loading ──────────────────────────────────────────────────────

  /// Attempts to fetch vocab pairs from the Gemini backend.
  /// On failure, falls back to the hardcoded [_vocabBank].
  /// Once questions are ready, transitions from loading screen → game screen.
  Future<void> _loadQuestions() async {
    try {
      // Try to get the current user's ID for personalized vocab
      final userNotifier = Provider.of<UserNotifier>(context, listen: false);
      final userId = userNotifier.user?.id ?? 'guest';

      // Call the backend API
      final apiPairs = await SpeedVocabService.fetchVocabPairs(
        userId: userId,
        numPairs: _questionsPerRound,
      );

      if (apiPairs != null && apiPairs.isNotEmpty) {
        // Successfully got vocab from Gemini – build questions
        // Collect all English translations for generating wrong options
        final allEnglish = apiPairs.map((p) => p.englishWord).toList();

        _questions = apiPairs.map((pair) {
          final wrongAnswers = allEnglish
              .where((e) => e != pair.englishWord)
              .toList()
            ..shuffle(_random);

          final options = <String>[
            pair.englishWord,
            ...wrongAnswers.take(3),
          ]..shuffle(_random);

          return _SpeedQuestion(
            prompt: pair.targetWord,
            correctAnswer: pair.englishWord,
            options: options,
          );
        }).toList();

        print('[SpeedVocab] Loaded ${_questions.length} questions from Gemini API');
      } else {
        // API returned empty – fall back
        _loadError = 'API returned no pairs';
        _questions = _buildFallbackQuestions();
        print('[SpeedVocab] Using fallback questions (API empty)');
      }
    } catch (e) {
      // Network error, timeout, etc. – fall back gracefully
      _loadError = e.toString();
      _questions = _buildFallbackQuestions();
      print('[SpeedVocab] Using fallback questions (error: $e)');
    }

    if (!mounted) return;

    // Transition from loading → gameplay
    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  /// Builds questions from the hardcoded vocab bank (offline fallback).
  List<_SpeedQuestion> _buildFallbackQuestions() {
    final entries = _vocabBank.entries.toList()..shuffle(_random);
    final selected = entries.take(_questionsPerRound).toList();
    final allEnglish = _vocabBank.values.toList();

    return selected.map((entry) {
      final wrongAnswers = allEnglish
          .where((value) => value != entry.value)
          .toList()
        ..shuffle(_random);

      final options = <String>[entry.value, ...wrongAnswers.take(3)]
        ..shuffle(_random);

      return _SpeedQuestion(
        prompt: entry.key,
        correctAnswer: entry.value,
        options: options,
      );
    }).toList();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  /// Starts the countdown. Called after questions have loaded.
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

  // ── Answer Handling ───────────────────────────────────────────────────────

  /// Processes a tap on an answer option.
  /// Shows colored feedback for 700ms, then advances.
  Future<void> _selectAnswer(String answer) async {
    if (_isFinished || _isRevealingFeedback) return;

    final currentQuestion = _questions[_questionIndex];
    final isCorrect = answer == currentQuestion.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _isRevealingFeedback = true;
    });

    if (isCorrect) {
      _correctAnswers += 1;
    }

    // Briefly show feedback colors before moving to the next question.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted || _isFinished) return;

    if (_questionIndex >= _questions.length - 1) {
      _finishGame();
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedAnswer = null;
      _isRevealingFeedback = false;
    });
  }

  // ── Color Helpers ─────────────────────────────────────────────────────────

  Color _getOptionBorderColor(String option, _SpeedQuestion question) {
    if (!_isRevealingFeedback) return const Color(0xFFE5E5E5);

    // During reveal:
    // - Correct option: green
    // - If the user selected a wrong answer: that selected option: red
    // - All other options: neutral
    if (option == question.correctAnswer) return const Color(0xFF58CC02);
    if (_selectedAnswer != null && option == _selectedAnswer) {
      return const Color(0xFFFF4B4B);
    }
    return const Color(0xFFE5E5E5);
  }

  Color _getOptionBackgroundColor(String option, _SpeedQuestion question) {
    if (!_isRevealingFeedback) return Colors.white;
    if (option == question.correctAnswer) return const Color(0xFFE7F5E0);
    if (_selectedAnswer != null && option == _selectedAnswer) {
      return const Color(0xFFFFE8E8);
    }
    return Colors.white;
  }

  Color _getOptionTextColor(String option, _SpeedQuestion question) {
    if (!_isRevealingFeedback) return Colors.black;
    if (option == question.correctAnswer) return const Color(0xFF2E7D32);
    if (_selectedAnswer != null && option == _selectedAnswer) {
      return const Color(0xFFC62828);
    }
    return Colors.black;
  }

  // ── Game Completion ───────────────────────────────────────────────────────

  /// Stops the timer, calculates XP, awards it, and shows a results dialog.
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

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: _isLoading ? _buildLoadingScreen() : _buildGameScreen(screenWidth),
    );
  }

  /// Loading screen shown while the API call is in-flight.
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF1CB0F6),
          ),
          SizedBox(height: 20),
          Text(
            'Loading vocabulary...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// The main gameplay UI — question counter, timer, prompt card, option buttons.
  Widget _buildGameScreen(double screenWidth) {
    final current = _questions[_questionIndex];

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: Column(
          key: ValueKey<int>(_questionIndex),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: Question counter + Timer pill ──────────────────────
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
                    color: _timeLeft <= 10
                        ? const Color(0xFFFFE8E8)
                        : const Color(0xFFF0F0F0),
                  ),
                  child: Text(
                    '$_timeLeft s',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _timeLeft <= 10
                          ? const Color(0xFFFF4B4B)
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Vocab Prompt Card ──────────────────────────────────────────
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

            // ── Answer Options ────────────────────────────────────────────
            ...current.options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    side: BorderSide(
                      color: _getOptionBorderColor(option, current),
                      width: 1.5,
                    ),
                    backgroundColor: _getOptionBackgroundColor(option, current),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                      _isRevealingFeedback ? null : () => _selectAnswer(option),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: _getOptionTextColor(option, current),
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

// ── Data Model ────────────────────────────────────────────────────────────────

/// Runtime question used during gameplay.
class _SpeedQuestion {
  const _SpeedQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  /// The word in the target language.
  final String prompt;
  /// The correct English translation.
  final String correctAnswer;
  /// All selectable options (includes correct answer, shuffled).
  final List<String> options;
}