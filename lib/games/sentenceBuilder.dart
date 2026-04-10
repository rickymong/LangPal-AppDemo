import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../userNotifier.dart';
import '../services/sentence_builder_service.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// SentenceBuilder – A timed fill-in-the-blank mini-game.
///
/// Questions are fetched from the Gemini-powered FastAPI backend via
/// [SentenceBuilderService]. If the backend is unreachable or returns an error,
/// the game gracefully falls back to a hardcoded question bank so the user can
/// still play offline.
///
/// UI is intentionally mirrored from [SpeedVocab] for design consistency.
/// ──────────────────────────────────────────────────────────────────────────────
class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({super.key, required this.xp});

  final int xp;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder> {
  // ── Game Configuration ────────────────────────────────────────────────────
  static const int _roundDurationSeconds = 45;
  static const int _questionsPerRound = 5;

  final Random _random = Random();
  Timer? _timer;

  // ── Audio Players ─────────────────────────────────────────────────────────
  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();

  // ── Loading State ─────────────────────────────────────────────────────────
  /// Whether the game is still fetching questions from the API.
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
  List<_SentenceQuestion> _questions = [];

  // ── Hardcoded Fallback Questions ──────────────────────────────────────────
  /// Used when the backend is unreachable so the game can still be played.
  static const List<_SentenceQuestionData> _sentenceBank = [
    _SentenceQuestionData(
      prompt: "The boy ___ to go on walks with his dog",
      correctAnswer: "likes",
      wrongAnswers: ["swims", "flights", "bakes"],
    ),
    _SentenceQuestionData(
      prompt: "I need to ___ water to stay hydrated",
      correctAnswer: "drink",
      wrongAnswers: ["eat", "sleep", "run"],
    ),
    _SentenceQuestionData(
      prompt: "She is going to the ___ to buy some bread",
      correctAnswer: "store",
      wrongAnswers: ["park", "school", "gym"],
    ),
    _SentenceQuestionData(
      prompt: "They ___ a very good movie last night",
      correctAnswer: "watched",
      wrongAnswers: ["read", "listened", "wrote"],
    ),
    _SentenceQuestionData(
      prompt: "My cat likes to ___ in the sun",
      correctAnswer: "sleep",
      wrongAnswers: ["bark", "fly", "drive"],
    ),
    _SentenceQuestionData(
      prompt: "Please ___ the door when you leave",
      correctAnswer: "close",
      wrongAnswers: ["open", "paint", "break"],
    ),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _preloadSounds();
    _loadQuestions(); // Async – fetches from API then starts the game
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    super.dispose();
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  /// Preloads correct/incorrect audio so playback is instant on tap.
  Future<void> _preloadSounds() async {
    await _correctPlayer.setSource(AssetSource('audio/games/vocab_match_correct.wav'));
    await _wrongPlayer.setSource(AssetSource('audio/games/vocab_match_incorrect.wav'));

    await _correctPlayer.setReleaseMode(ReleaseMode.stop);
    await _wrongPlayer.setReleaseMode(ReleaseMode.stop);
  }

  // ── Question Loading ──────────────────────────────────────────────────────

  /// Attempts to fetch questions from the Gemini backend.
  /// On failure, falls back to the hardcoded [_sentenceBank].
  /// Once questions are ready, transitions from loading screen → game screen.
  Future<void> _loadQuestions() async {
    try {
      // Try to get the current user's ID for personalized questions
      final userNotifier = Provider.of<UserNotifier>(context, listen: false);
      final userId = userNotifier.user?.id ?? 'guest';

      // Call the backend API
      final apiQuestions = await SentenceBuilderService.fetchQuestions(
        userId: userId,
        numQuestions: _questionsPerRound,
      );

      if (apiQuestions != null && apiQuestions.isNotEmpty) {
        // Successfully got questions from Gemini – convert to internal model
        _questions = apiQuestions.map((q) {
          final options = List<String>.from(q.options)..shuffle(_random);
          return _SentenceQuestion(
            prompt: q.sentence,
            correctAnswer: q.answer,
            options: options,
          );
        }).toList();
        print('[SentenceBuilder] Loaded ${_questions.length} questions from Gemini API');
      } else {
        // API returned empty – fall back
        _loadError = 'API returned no questions';
        _questions = _buildFallbackQuestions();
        print('[SentenceBuilder] Using fallback questions (API empty)');
      }
    } catch (e) {
      // Network error, timeout, etc. – fall back gracefully
      _loadError = e.toString();
      _questions = _buildFallbackQuestions();
      print('[SentenceBuilder] Using fallback questions (error: $e)');
    }

    if (!mounted) return;

    // Transition from loading → gameplay
    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  /// Builds questions from the hardcoded bank (offline fallback).
  List<_SentenceQuestion> _buildFallbackQuestions() {
    final available = List<_SentenceQuestionData>.from(_sentenceBank)..shuffle(_random);
    final selected = available.take(_questionsPerRound).toList();

    return selected.map((data) {
      final options = <String>[data.correctAnswer, ...data.wrongAnswers]..shuffle(_random);
      return _SentenceQuestion(
        prompt: data.prompt,
        correctAnswer: data.correctAnswer,
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
  /// Plays audio, shows colored feedback for 700ms, then advances.
  Future<void> _selectAnswer(String answer) async {
    if (_isFinished || _isRevealingFeedback) return;

    final currentQuestion = _questions[_questionIndex];
    final isCorrect = answer == currentQuestion.correctAnswer;

    // Audio feedback
    if (isCorrect) {
      _correctPlayer.seek(Duration.zero);
      _correctPlayer.resume();
      _correctAnswers += 1;
    } else {
      _wrongPlayer.seek(Duration.zero);
      _wrongPlayer.resume();
    }

    // Show colored feedback
    setState(() {
      _selectedAnswer = answer;
      _isRevealingFeedback = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted || _isFinished) return;

    // Advance or finish
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

  Color _getOptionBorderColor(String option, _SentenceQuestion question) {
    if (!_isRevealingFeedback) return const Color(0xFFE5E5E5);
    if (option == question.correctAnswer) return const Color(0xFF58CC02);
    if (_selectedAnswer == option) return const Color(0xFFFF4B4B);
    return const Color(0xFFE5E5E5);
  }

  Color _getOptionBackgroundColor(String option, _SentenceQuestion question) {
    if (!_isRevealingFeedback) return Colors.white;
    if (option == question.correctAnswer) return const Color(0xFFE7F5E0);
    if (_selectedAnswer == option) return const Color(0xFFFFE8E8);
    return Colors.white;
  }

  Color _getOptionTextColor(String option, _SentenceQuestion question) {
    if (!_isRevealingFeedback) return Colors.black;
    if (option == question.correctAnswer) return const Color(0xFF2E7D32);
    if (_selectedAnswer == option) return const Color(0xFFC62828);
    return Colors.black;
  }

  // ── Game Completion ───────────────────────────────────────────────────────

  /// Stops the timer, calculates XP, awards it, and shows a results dialog.
  void _finishGame() {
    if (_isFinished) return;

    setState(() {
      _isFinished = true;
    });
    _timer?.cancel();

    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    final accuracy = _correctAnswers / _questions.length;

    // XP tiers: >=80% → full, >=40% → half, <40% → 0
    final earnedXp = accuracy >= 0.8
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
          'Sentence Builder',
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
            color: Color(0xFF58CC02),
          ),
          SizedBox(height: 20),
          Text(
            'Generating questions...',
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
      child: Column(
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

          // ── Sentence Prompt Card ───────────────────────────────────────
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
                  'Fill in the blank',
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

/// Static definition used in the hardcoded fallback bank.
class _SentenceQuestionData {
  const _SentenceQuestionData({
    required this.prompt,
    required this.correctAnswer,
    required this.wrongAnswers,
  });

  final String prompt;
  final String correctAnswer;
  final List<String> wrongAnswers;
}

/// Runtime question used during gameplay.
class _SentenceQuestion {
  const _SentenceQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final String correctAnswer;
  final List<String> options;
}