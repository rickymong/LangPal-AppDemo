import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A single grammar question returned by the Gemini backend.
class GrammarQuestion {
  final String question;
  final String answer;
  final List<String> options;
  final String? explanation;

  const GrammarQuestion({
    required this.question,
    required this.answer,
    required this.options,
    this.explanation,
  });

  factory GrammarQuestion.fromJson(Map<String, dynamic> json) {
    return GrammarQuestion(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      explanation: json['explanation'] as String?,
    );
  }
}

/// Fetches Gemini-generated grammar questions from the backend.
class GrammarQuestService {
  /// Calls POST /games/grammar/start.
  /// Returns null on failure so the game can fall back to hardcoded questions.
  static Future<List<GrammarQuestion>?> fetchQuestions({
    required String userId,
    int numQuestions = 6,
  }) async {
    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null || baseUrl.isEmpty) return null;

      final uri = Uri.parse('$baseUrl/games/grammar/start');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'num_questions': numQuestions,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['questions'] as List<dynamic>? ?? [];
      if (raw.isEmpty) return null;

      return raw
          .map((q) => GrammarQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[GrammarQuestService] Error: $e');
      return null;
    }
  }
}
