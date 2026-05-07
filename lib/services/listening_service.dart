import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ListeningPracticeData {
  final String language;
  final String passage;
  final List<String> questions;
  final List<String> answers;
  final String audioUrl;

  const ListeningPracticeData({
    required this.language,
    required this.passage,
    required this.questions,
    required this.answers,
    required this.audioUrl,
  });

  factory ListeningPracticeData.fromJson(Map<String, dynamic> json) {
    return ListeningPracticeData(
      language: json['language'] as String? ?? '',
      passage: json['passage'] as String? ?? '',
      questions: List<String>.from(json['questions'] ?? const []),
      answers: List<String>.from(json['answers'] ?? const []),
      audioUrl: json['audio_url'] as String? ?? '',
    );
  }
}

class ListeningService {
  static Future<ListeningPracticeData?> fetchPractice({
    required String userId,
  }) async {
    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null || baseUrl.isEmpty) return null;

      final uri = Uri.parse('$baseUrl/practice/listening');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final parsed = ListeningPracticeData.fromJson(data);

      if (parsed.questions.isEmpty || parsed.answers.isEmpty) return null;
      return parsed;
    } catch (e) {
      print('[ListeningService] Error: $e');
      return null;
    }
  }
}
