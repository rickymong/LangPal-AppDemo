import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:langpal_prototype/services/conversation_service.dart';
import 'package:langpal_prototype/services/record_service.dart';

class LivePracticeScreen extends StatefulWidget {
  const LivePracticeScreen({super.key});

  @override
  State<LivePracticeScreen> createState() => _LivePracticeScreenState();
}

class _LivePracticeScreenState extends State<LivePracticeScreen> {
  final RecordService _recordService = RecordService();
  final ConversationService _conversationService = ConversationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isRecording = false;
  bool isBeakOpen = false;
  bool isAISpeaking = false;
  String userTranscript = '';
  String aiTranscript = '';
  String stateText = 'Ready to speak';
  bool isProcessing = false;
  int turnCount = 0;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _recordService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// AI starts with initial greeting
  Future<void> _startConversation() async {
    setState(() {
      stateText = 'AI Starting conversation...';
      isProcessing = true;
    });

    final response = await _conversationService.sendConversation(
      userId: 'test_user_123',
      audioBase64: '',
    );

    if (response != null) {
      setState(() {
        aiTranscript = response['target_text'] ?? '';
        isBeakOpen = true;
        isAISpeaking = true;
        stateText = 'AI Speaking...';
      });

      if (response['audio_url'] != null) {
        await _playAudio(response['audio_url']);
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isBeakOpen = false;
            isAISpeaking = false;
            stateText = 'Ready to speak';
            isProcessing = false;
          });
        }
      });
    } else {
      setState(() {
        isProcessing = false;
        stateText = 'Error starting conversation';
      });
    }
  }

  /// Start recording when mic button is pressed
  Future<void> _startRecording() async {
    final success = await _recordService.startRecording();
    if (success) {
      setState(() {
        isRecording = true;
        userTranscript = '';
        stateText = 'Recording...';
      });
    } else {
      _showError('Failed to start recording');
    }
  }

  /// Stop recording and send to backend
  Future<void> _stopRecording() async {
    if (!isRecording) return;

    setState(() {
      isProcessing = true;
      stateText = 'Processing...';
    });

    final audioBase64 = await _recordService.stopRecording();

    if (audioBase64 != null && audioBase64.isNotEmpty) {
      setState(() {
        isRecording = false;
      });

      await _sendAudioToBackend(audioBase64);
    } else {
      setState(() {
        isRecording = false;
        isProcessing = false;
        stateText = 'No audio recorded. Try again.';
      });
    }
  }

  /// Send audio to backend and get AI response
  Future<void> _sendAudioToBackend(String audioBase64) async {
    try {
      final response = await _conversationService.sendConversation(
        userId: 'test_user_123',
        audioBase64: audioBase64,
      );

      if (response != null) {
        setState(() {
          userTranscript = response['transcript'] ?? 'Audio recorded';
          aiTranscript = response['target_text'] ?? '';
          turnCount++;
        });

        setState(() {
          isBeakOpen = true;
          isAISpeaking = true;
          stateText = 'AI Speaking...';
        });

        if (response['audio_url'] != null) {
          await _playAudio(response['audio_url']);
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              isBeakOpen = false;
              isAISpeaking = false;
              stateText = 'Ready to speak';
              isProcessing = false;
            });
          }
        });
      } else {
        setState(() {
          isProcessing = false;
          stateText = 'Error communicating with AI. Try again.';
        });
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// Play audio from URL
  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 248, 233),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            if (isRecording) {
              _recordService.cancelRecording();
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Tutor',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Connected • $turnCount turns',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50] ?? Colors.white,
              Colors.grey[100] ?? Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mascot placeholder
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isBeakOpen = !isBeakOpen;
                              });
                            },
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAISpeaking
                                    ? Colors.orange[300]
                                    : Colors.blue[300],
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAISpeaking
                                            ? Colors.orange
                                            : Colors.blue)
                                        .withOpacity(0.3),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isBeakOpen ? '🐦' : '🤖',
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAISpeaking ? 'AI Speaking...' : 'Your Turn',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Transcript area
                      Container(
                        width: MediaQuery.of(context).size.width - 48,
                        constraints: const BoxConstraints(minHeight: 140),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300] ?? Colors.grey,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User transcript
                              if (userTranscript.isNotEmpty) ...[
                                Text(
                                  'You:',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userTranscript,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  color: Colors.grey[300],
                                  height: 1,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // AI transcript
                              if (aiTranscript.isNotEmpty) ...[
                                Text(
                                  'AI:',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  aiTranscript,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  isProcessing
                                      ? 'Waiting for response...'
                                      : 'Speak to practice with AI',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // State indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isRecording
                              ? Colors.red[100]
                              : (isProcessing
                                  ? Colors.blue[100]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stateText,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: isRecording
                                ? Colors.red[700]
                                : (isProcessing
                                    ? Colors.blue[700]
                                    : Colors.grey[700]),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic button
                      GestureDetector(
                        onLongPressStart: (_) async {
                          if (!isProcessing && !isAISpeaking) {
                            await _startRecording();
                          }
                        },
                        onLongPressEnd: (_) async {
                          if (isRecording) {
                            await _stopRecording();
                          }
                        },
                        onLongPressCancel: () async {
                          if (isRecording) {
                            await _recordService.cancelRecording();
                            setState(() {
                              isRecording = false;
                              stateText = 'Ready to speak';
                            });
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRecording
                                ? Colors.blue[400]
                                : Colors.white,
                            border: Border.all(
                              color: Colors.blue[400] ?? Colors.blue,
                              width: 2,
                            ),
                            boxShadow: isRecording
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.mic,
                              size: 32,
                              color: isRecording
                                  ? Colors.white
                                  : Colors.blue[400],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // End call button
                      GestureDetector(
                        onTap: () {
                          if (isRecording) {
                            _recordService.cancelRecording();
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red[400],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.call_end,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hold to speak',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
