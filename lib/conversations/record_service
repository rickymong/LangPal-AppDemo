import 'dart:io';
import 'package:record/record.dart';
import 'dart:convert';

class RecordService {
  static final RecordService _instance = RecordService._internal();

  factory RecordService() => _instance;

  RecordService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (await _recorder.hasPermission()) {
        // Get temp directory for audio file
        final directory = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = '${directory.path}/audio_$timestamp.m4a';

        // Start recording to file
        await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

        _isRecording = true;
        print('Recording started: $_recordingPath');
        return true;
      } else {
        print('Microphone permission denied');
        return false;
      }
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return base64 encoded audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('No recording in progress');
        return null;
      }

      // Stop recording
      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        print('Failed to stop recording');
        return null;
      }

      print('Recording stopped: $path');

      // Read audio file
      final file = File(path);
      if (!await file.exists()) {
        print('Audio file does not exist');
        return null;
      }

      // Convert to base64
      final audioBytes = await file.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      print('Audio converted to base64 (${audioBytes.length} bytes)');

      // Clean up
      await file.delete();
      _recordingPath = null;

      return audioBase64;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        if (_recordingPath != null) {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        _recordingPath = null;
        print('Recording cancelled');
      }
    } catch (e) {
      print('Error cancelling recording: $e');
    }
  }

  /// Dispose recorder
  void dispose() {
    _recorder.dispose();
  }
}
