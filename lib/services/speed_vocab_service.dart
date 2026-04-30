import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Data model for a single vocab pair returned by the Gemini-powered backend.
class VocabPair {
  /// The word in the target language (e.g. "bonjour").
  final String targetWord;

  /// The English translation (e.g. "hello").
  final String englishWord;

  /// Optional short hint for the word.
  final String? hint;

  const VocabPair({
    required this.targetWord,
    required this.englishWord,
    this.hint,
  });

  factory VocabPair.fromJson(Map<String, dynamic> json) {
    return VocabPair(
      targetWord: json['target_word'] as String? ?? '',
      englishWord: json['english_word'] as String? ?? '',
      hint: json['hint'] as String?,
    );
  }
}

/// Service that communicates with the FastAPI backend to fetch
/// Gemini-generated vocabulary pairs for the Speed Vocab game.
///
/// Calls `POST /games/matching/start` which uses
/// [generate_matching_pairs] in the backend's ai_utils.py.
class SpeedVocabService {
  /// Fetches [numPairs] vocabulary pairs from the backend.
  ///
  /// [userId] — the logged-in user's ID so the backend can
  ///            select vocabulary based on their target language.
  /// [numPairs] — how many vocab pairs to request (default 8
  ///              to match Speed Vocab's question count).
  ///
  /// Returns a list of [VocabPair] on success, or `null` if the
  /// request fails, allowing the game to fall back to hardcoded words.
  static Future<List<VocabPair>?> fetchVocabPairs({
    required String userId,
    int numPairs = 8,
  }) async {
    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null || baseUrl.isEmpty) {
        print('[SpeedVocabService] BACKEND_URL not set in .env');
        return null;
      }

      final uri = Uri.parse('$baseUrl/games/matching/start');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'num_pairs': numPairs,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('[SpeedVocabService] Backend returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawPairs = data['pairs'] as List<dynamic>? ?? [];

      if (rawPairs.isEmpty) {
        print('[SpeedVocabService] Backend returned 0 pairs');
        return null;
      }

      return rawPairs
          .map((p) => VocabPair.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[SpeedVocabService] Error fetching vocab pairs: $e');
      return null;
    }
  }
}
