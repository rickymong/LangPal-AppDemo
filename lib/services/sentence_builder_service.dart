import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Data model representing a single fill-in-the-blank question
/// returned by the Gemini-powered backend.
class SentenceQuestion {
  /// The sentence body containing "___" where the blank is.
  final String sentence;

  /// The correct word that fills the blank.
  final String answer;

  /// All selectable options (includes the correct answer, shuffled).
  final List<String> options;

  /// Optional short English explanation of why the answer is correct.
  final String? explanation;

  const SentenceQuestion({
    required this.sentence,
    required this.answer,
    required this.options,
    this.explanation,
  });

  /// Constructs a [SentenceQuestion] from a JSON map returned by the backend.
  factory SentenceQuestion.fromJson(Map<String, dynamic> json) {
    return SentenceQuestion(
      sentence: json['sentence'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      explanation: json['explanation'] as String?,
    );
  }
}

/// Service that communicates with the FastAPI backend to fetch
/// Gemini-generated fill-in-the-blank questions for the Sentence Builder game.
class SentenceBuilderService {
  /// Fetches [numQuestions] fill-in-the-blank questions from the backend.
  ///
  /// [userId] — the logged-in user's ID so the backend can personalize
  ///            questions based on their learning context.
  /// [numQuestions] — how many questions to request (default 5).
  ///
  /// Returns a list of [SentenceQuestion] on success, or `null` if the
  /// request fails (network error, bad response, backend down, etc.).
  static Future<List<SentenceQuestion>?> fetchQuestions({
    required String userId,
    int numQuestions = 5,
  }) async {
    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null || baseUrl.isEmpty) {
        print('[SentenceBuilderService] BACKEND_URL not set in .env');
        return null;
      }

      final uri = Uri.parse('$baseUrl/games/fill-blanks/start');

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

      if (response.statusCode != 200) {
        print('[SentenceBuilderService] Backend returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawQuestions = data['questions'] as List<dynamic>? ?? [];

      if (rawQuestions.isEmpty) {
        print('[SentenceBuilderService] Backend returned 0 questions');
        return null;
      }

      return rawQuestions
          .map((q) => SentenceQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[SentenceBuilderService] Error fetching questions: $e');
      return null;
    }
  }
}
