import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/listening_service.dart';
import '../userNotifier.dart';

class ListeningChallenge extends StatefulWidget {
  const ListeningChallenge({super.key, required this.xp});

  final int xp;

  @override
  State<ListeningChallenge> createState() => _ListeningChallengeState();
}

class _ListeningChallengeState extends State<ListeningChallenge> {
  static const int _roundDurationSeconds = 120;

  final AudioPlayer _player = AudioPlayer();
  final List<TextEditingController> _answerControllers = [];
  Timer? _timer;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isFinished = false;
  bool _audioReady = false;

  int _timeLeft = _roundDurationSeconds;
  int _correctAnswers = 0;

  ListeningPracticeData? _practiceData;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPractice();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPractice() async {
    try {
      final userId =
          Provider.of<UserNotifier>(context, listen: false).user?.id ?? 'guest';
      final data = await ListeningService.fetchPractice(userId: userId);

      if (data == null) {
        _practiceData = _fallbackPractice();
      } else {
        _practiceData = data;
      }

      final questionCount = _practiceData!.questions.length;
      _answerControllers
        ..clear()
        ..addAll(
          List.generate(questionCount, (_) => TextEditingController()),
        );

      if (_practiceData!.audioUrl.isNotEmpty) {
        try {
          await _player.setSource(UrlSource(_practiceData!.audioUrl));
          _audioReady = true;
        } catch (_) {
          _audioReady = false;
        }
      }
    } catch (e) {
      _loadError = e.toString();
      _practiceData = _fallbackPractice();
      final questionCount = _practiceData!.questions.length;
      _answerControllers
        ..clear()
        ..addAll(
          List.generate(questionCount, (_) => TextEditingController()),
        );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _startTimer();
  }

  ListeningPracticeData _fallbackPractice() {
    return const ListeningPracticeData(
      language: 'Spanish',
      passage:
          'Ana wakes up early every morning. She drinks coffee and walks to the market to buy fresh fruit. On weekends, she meets her brother in the park.',
      questions: [
        'What does Ana drink in the morning?',
        'Where does Ana go after waking up?',
        'Who does she meet on weekends?'
      ],
      answers: ['coffee', 'market', 'brother'],
      audioUrl: '',
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isFinished) return;
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _submitAnswers();
        return;
      }
      setState(() => _timeLeft -= 1);
    });
  }

  Future<void> _toggleAudioPlayback() async {
    if (!_audioReady) return;
    final state = _player.state;
    if (state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    if (mounted) setState(() {});
  }

  String _normalize(String value) {
    final lowered = value.toLowerCase().trim();
    final cleaned = lowered.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _submitAnswers() async {
    if (_isFinished || _isSubmitting || _practiceData == null) return;

    setState(() => _isSubmitting = true);

    _timer?.cancel();
    final expected = _practiceData!.answers;
    int correct = 0;

    for (int i = 0; i < expected.length && i < _answerControllers.length; i++) {
      final userAnswer = _normalize(_answerControllers[i].text);
      final expectedAnswer = _normalize(expected[i]);
      if (userAnswer.isNotEmpty && userAnswer == expectedAnswer) {
        correct += 1;
      }
    }

    final accuracy = expected.isEmpty ? 0.0 : correct / expected.length;
    final earnedXp = accuracy >= 0.7
        ? widget.xp
        : (accuracy >= 0.4 ? (widget.xp / 2).round() : 0);

    if (earnedXp > 0) {
      Provider.of<UserNotifier>(context, listen: false).completeGame(earnedXp);
    }

    _correctAnswers = correct;
    _isFinished = true;
    _isSubmitting = false;

    if (!mounted) return;
    setState(() {});

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Listening Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $_correctAnswers / ${expected.length}'),
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
        );
      },
    );
  }

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
          'Listening Challenge',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading ? _buildLoading() : _buildGame(screenWidth),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF58CC02)),
          SizedBox(height: 16),
          Text(
            'Preparing listening challenge...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGame(double screenWidth) {
    final data = _practiceData!;
    final isPlaying = _player.state == PlayerState.playing;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.language,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _timeLeft <= 20
                      ? const Color(0xFFFFE8E8)
                      : const Color(0xFFF0F0F0),
                ),
                child: Text(
                  '$_timeLeft s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _timeLeft <= 20 ? const Color(0xFFFF4B4B) : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listen to the passage and answer each question.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (_audioReady)
                  ElevatedButton.icon(
                    onPressed: _toggleAudioPlayback,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(isPlaying ? 'Pause Audio' : 'Play Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Text(
                    'Audio unavailable. You can still answer from the fallback passage below.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                if (!_audioReady) ...[
                  const SizedBox(height: 10),
                  Text(
                    data.passage,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < data.questions.length; i++) ...[
            Text(
              '${i + 1}. ${data.questions[i]}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answerControllers[i],
              enabled: !_isFinished,
              decoration: InputDecoration(
                hintText: 'Type your answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ElevatedButton(
            onPressed: _isFinished ? null : _submitAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CB0F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_isSubmitting ? 'Submitting...' : 'Submit Answers'),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 10),
            Text(
              'Network note: using fallback listening set.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
