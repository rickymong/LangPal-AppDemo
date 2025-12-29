
// ChatMessage model
class ChatMessage {
  final int id;
  final String userId;
  final String aiID;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.aiID,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });

}
