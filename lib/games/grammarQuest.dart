import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../userNotifier.dart';
import '../services/grammar_quest_service.dart';

/// Grammar Quest – A timed grammar multiple-choice game.
///
/// Questions come from Gemini via [GrammarQuestService].
/// Falls back to hardcoded questions if the backend is unreachable.
/// UI mirrors SpeedVocab / SentenceBuilder for consistency.
class GrammarQuest extends StatefulWidget {
  const GrammarQuest({super.key, required this.xp});

  final int xp;

  @override
  State<GrammarQuest> createState() => _GrammarQuestState();
}

class _GrammarQuestState extends State<GrammarQuest> {
  static const int _roundDurationSeconds = 60;
  static const int _questionsPerRound = 6;

  final Random _random = Random();
  Timer? _timer;

  bool _isLoading = true;
  int _timeLeft = _roundDurationSeconds;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  bool _isFinished = false;
  bool _isRevealingFeedback = false;
  String? _selectedAnswer;

  List<_GrammarQ> _questions = [];

  // Hardcoded fallback questions (French grammar)
  static const List<_GrammarQData> _fallbackBank = [
    _GrammarQData(
      question: "Choose the correct verb form:\nJe ___ français.",
      correctAnswer: "parle",
      wrongAnswers: ["parles", "parlons", "parlez"],
    ),
    _GrammarQData(
      question: "Which article fits?\n___ maison est grande.",
      correctAnswer: "La",
      wrongAnswers: ["Le", "Les", "Un"],
    ),
    _GrammarQData(
      question: "Select the correct past tense:\nHier, il ___ au cinéma.",
      correctAnswer: "est allé",
      wrongAnswers: ["va", "allait", "ira"],
    ),
    _GrammarQData(
      question: "Pick the right preposition:\nElle habite ___ Paris.",
      correctAnswer: "à",
      wrongAnswers: ["en", "de", "sur"],
    ),
    _GrammarQData(
      question: "Complete the sentence:\nNous ___ contents.",
      correctAnswer: "sommes",
      wrongAnswers: ["avons", "êtes", "sont"],
    ),
    _GrammarQData(
      question: "Which is correct?\nIls ___ beaucoup de livres.",
      correctAnswer: "ont",
      wrongAnswers: ["sont", "avez", "as"],
    ),
    _GrammarQData(
      question: "Choose the right adjective agreement:\nLes filles sont ___.",
      correctAnswer: "contentes",
      wrongAnswers: ["content", "contents", "contente"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Fetches questions from API, falling back to hardcoded on failure.
  Future<void> _loadQuestions() async {
    try {
      final userNotifier = Provider.of<UserNotifier>(context, listen: false);
      final userId = userNotifier.user?.id ?? 'guest';

      final apiQuestions = await GrammarQuestService.fetchQuestions(
        userId: userId,
        numQuestions: _questionsPerRound,
      );

      if (apiQuestions != null && apiQuestions.isNotEmpty) {
        _questions = apiQuestions.map((q) {
          final opts = List<String>.from(q.options)..shuffle(_random);
          return _GrammarQ(
            prompt: q.question,
            correctAnswer: q.answer,
            options: opts,
            explanation: q.explanation,
          );
        }).toList();
      } else {
        _questions = _buildFallback();
      }
    } catch (_) {
      _questions = _buildFallback();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _startTimer();
  }

  List<_GrammarQ> _buildFallback() {
    final bank = List<_GrammarQData>.from(_fallbackBank)..shuffle(_random);
    return bank.take(_questionsPerRound).map((d) {
      final opts = <String>[d.correctAnswer, ...d.wrongAnswers]..shuffle(_random);
      return _GrammarQ(prompt: d.question, correctAnswer: d.correctAnswer, options: opts);
    }).toList();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isFinished) return;
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _finishGame();
        return;
      }
      setState(() => _timeLeft -= 1);
    });
  }

  /// Handles answer selection with 700ms feedback delay.
  Future<void> _selectAnswer(String answer) async {
    if (_isFinished || _isRevealingFeedback) return;

    final current = _questions[_questionIndex];
    if (answer == current.correctAnswer) _correctAnswers += 1;

    setState(() {
      _selectedAnswer = answer;
      _isRevealingFeedback = true;
    });

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

  // Color helpers
  Color _borderColor(String opt, _GrammarQ q) {
    if (!_isRevealingFeedback) return const Color(0xFFE5E5E5);
    if (opt == q.correctAnswer) return const Color(0xFF58CC02);
    if (_selectedAnswer == opt) return const Color(0xFFFF4B4B);
    return const Color(0xFFE5E5E5);
  }

  Color _bgColor(String opt, _GrammarQ q) {
    if (!_isRevealingFeedback) return Colors.white;
    if (opt == q.correctAnswer) return const Color(0xFFE7F5E0);
    if (_selectedAnswer == opt) return const Color(0xFFFFE8E8);
    return Colors.white;
  }

  Color _textColor(String opt, _GrammarQ q) {
    if (!_isRevealingFeedback) return Colors.black;
    if (opt == q.correctAnswer) return const Color(0xFF2E7D32);
    if (_selectedAnswer == opt) return const Color(0xFFC62828);
    return Colors.black;
  }

  /// Finishes the game and shows results dialog.
  void _finishGame() {
    if (_isFinished) return;
    setState(() => _isFinished = true);
    _timer?.cancel();

    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    final accuracy = _correctAnswers / _questions.length;
    final earnedXp = accuracy >= 0.7
        ? widget.xp
        : (accuracy >= 0.4 ? (widget.xp / 2).round() : 0);

    if (earnedXp > 0) userNotifier.completeGame(earnedXp);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quest Complete'),
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
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

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
          'Grammar Quest',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading ? _loadingWidget() : _gameWidget(sw),
    );
  }

  Widget _loadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF4B4B)),
          SizedBox(height: 20),
          Text('Generating grammar questions...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _gameWidget(double sw) {
    final current = _questions[_questionIndex];

    return Padding(
      padding: EdgeInsets.all(sw * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q ${_questionIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _timeLeft <= 10 ? const Color(0xFFFFE8E8) : const Color(0xFFF0F0F0),
                ),
                child: Text('$_timeLeft s',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _timeLeft <= 10 ? const Color(0xFFFF4B4B) : Colors.black,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              children: [
                Text('Choose the correct answer',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Text(current.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...current.options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    side: BorderSide(color: _borderColor(opt, current), width: 1.5),
                    backgroundColor: _bgColor(opt, current),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isRevealingFeedback ? null : () => _selectAnswer(opt),
                  child: Text(opt,
                      style: TextStyle(
                          color: _textColor(opt, current), fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              )),

          // Show explanation after revealing feedback
          if (_isRevealingFeedback && current.explanation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFFFFA000), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(current.explanation!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data Models ─────────────────────────────────────────────────────────────

class _GrammarQData {
  const _GrammarQData({
    required this.question,
    required this.correctAnswer,
    required this.wrongAnswers,
  });
  final String question;
  final String correctAnswer;
  final List<String> wrongAnswers;
}

class _GrammarQ {
  const _GrammarQ({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
    this.explanation,
  });
  final String prompt;
  final String correctAnswer;
  final List<String> options;
  final String? explanation;
}
