
// ChatMessage model
class ChatMessage {
  final int id;
  final String userId;
  final String aiID;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  /// For AI reply messages: the English translation of [text].
  final String? englishText;

  /// For AI reply messages: a short grammar / phrasing tip.
  final String? tip;

  /// For AI reply messages: a follow-up question in the target language.
  final String? followUp;

  /// When true this is a transient "thinking" bubble shown while awaiting a reply.
  final bool isLoading;

  /// When set, this message should replace the loading bubble with this id.
  final int? replacesId;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.aiID,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.englishText,
    this.tip,
    this.followUp,
    this.isLoading = false,
    this.replacesId,
  });

}

