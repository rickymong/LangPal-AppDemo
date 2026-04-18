import 'package:http/http.dart' as http;
import 'dart:convert';

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();

  factory ConversationService() => _instance;

  ConversationService._internal();

  // Backend URL - UPDATE THIS TO YOUR SERVER
  static const String backendUrl = 'http://127.0.0.1:8000';

  /// Send audio to backend and get AI response
  Future<Map<String, dynamic>?> sendConversation({
    required String userId,
    required String audioBase64,
  }) async {
    try {
      final url = Uri.parse('$backendUrl/conversation');
      
      final body = {
        'user_id': userId,
        'audio_base64': audioBase64,
        'mime_type': 'audio/m4a',
      };

      print('📤 Sending to backend: $url');
      print('   User: $userId');
      print('   Audio size: ${audioBase64.length} chars');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Backend request timeout');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Success: $data');
        return data;
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Test connection to backend
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$backendUrl/');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      print('Backend connected: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection failed: $e');
      return false;
    }
  }
}
