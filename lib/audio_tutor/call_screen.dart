// call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallScreen extends StatefulWidget {
  final String characterName;
  final String language; // e.g. "Spanish"

  const CallScreen({
    super.key,
    required this.characterName,
    required this.language,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  // --- State ---
  bool _isRecording = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callEnded = false;
  int _seconds = 0;
  Timer? _timer;

  // --- Waveform animation ---
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // TODO: Connect WebSocket here
    // _wsService.connect(onMessage: _handleServerMessage);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_callEnded) setState(() => _seconds++);
    });
  }

  String get _formattedTime {
    final m = _seconds ~/ 60;
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // --- PTT Handlers ---
  void _onPttDown() {
    if (_callEnded) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRecording = true);
    // TODO: _audioRecorder.start()
    // TODO: _wsService.send({'type': 'recording_start'})
  }

  void _onPttUp() {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    setState(() => _isRecording = false);
    // TODO: final audioBlob = await _audioRecorder.stop()
    // TODO: _wsService.sendBinary(audioBlob)
  }

  void _hangUp() {
    HapticFeedback.heavyImpact();
    setState(() => _callEnded = true);
    _timer?.cancel();
    // TODO: _wsService.close()
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    // TODO: _wsService.dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildCallHeader(),
            SizedBox(height: screenHeight * 0.04),
           // _buildWaveform(),
           // const SizedBox(height: 40),
            //_buildSecondaryControls(),
            const Divider(color: Colors.white12, indent: 24, endIndent: 24),
            SizedBox(height: screenHeight * 0.2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // _iconButton(
                //   icon: _isMuted ? Icons.mic_off : Icons.mic_off_outlined,
                //   label: 'Mute',
                //   active: _isMuted,
                //   onTap: () => setState(() => _isMuted = !_isMuted),
                // ),
                _buildPttButton(),
                _buildHangUpButton(),
              ],
            ),
            //const Spacer(),
            
            SizedBox(height: screenHeight * 0.12),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.05),
        // Avatar
        Container(
          width: screenWidth * 0.5,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF534AB7), Color(0xFF7F77DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        Text(
          widget.characterName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          widget.language,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _callEnded
                      ? Colors.grey
                      : Color.lerp(
                          Colors.green,
                          const Color.fromARGB(69, 76, 175, 79),
                          _waveController.value,
                        )!,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.015,),
            Text(
              _callEnded ? 'Call ended' : 'Connected • $_formattedTime',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final barHeights = [
      14.0,
      22,
      32,
      18,
      40,
      28,
      16,
      36,
      24,
      42,
      20,
      34,
      26,
      38,
      18
    ];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barHeights.length, (i) {
            final phase = (i / barHeights.length + _waveController.value) % 1.0;
            final scale =
                0.3 + 0.7 * (0.5 + 0.5 * (phase * 2 * 3.14159).abs() % 1);
            return Container(
              width: 3,
              height: barHeights[i] * scale,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _isRecording
                    ? const Color.fromARGB(193, 244, 67, 54)
                    : const Color.fromARGB(145, 127, 119, 221),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSecondaryControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic_off_outlined,
            label: 'Mute',
            active: _isMuted,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          _iconButton(
            icon: Icons.volume_up_outlined,
            label: 'Speaker',
            active: _isSpeakerOn,
            onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white24 : Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon, color: Colors.white70, size: 26),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _buildPttButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonSize = screenWidth * 0.2;
    final innerSize = buttonSize * 0.69;
    return Column(
      children: [
        Text(
          _isRecording ? 'Recording...' : 'Hold to speak',
          style: TextStyle(
            color: _isRecording ? Colors.red.shade300 : Colors.white30,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        GestureDetector(
          onTapDown: (_) => _onPttDown(),
          onTapUp: (_) => _onPttUp(),
          onPanEnd: (_) => _onPttUp(), // drag-off safety
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? const Color(0xFF7F77DD)
                  : const Color(0xFF7F77DD).withOpacity(0.15),
              border: Border.all(
                color: const Color(0xFF7F77DD),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.white24
                      : const Color(0xFF7F77DD).withOpacity(0.25),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHangUpButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonSize = screenWidth * 0.2;
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.05),
        GestureDetector(
          onTap: _hangUp,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE24B4A),
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
