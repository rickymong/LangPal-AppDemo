import 'dart:async';

import '../types/chatMessage.dart';

/// A thin broadcast bus for chat messages.
///
/// [sendMessage]    – adds a new message (user or AI) to the stream.
/// [replaceThinking] – emits the real AI reply tagged with [replacesId]
///                     so [ChatPage] can swap out the loading bubble.
class MessageService {
  static final MessageService _instance = MessageService._internal();

  factory MessageService() => _instance;

  MessageService._internal();

  final StreamController<ChatMessage> _controller =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream => _controller.stream;

  void sendMessage(ChatMessage message) {
    _controller.add(message);
  }

  /// Emit [realMessage] with [replacesId] set so the UI knows which
  /// loading bubble to swap out.
  void replaceThinking(int thinkingId, ChatMessage realMessage) {
    // We reuse the same stream; the listener checks replacesId.
    final tagged = ChatMessage(
      id: realMessage.id,
      userId: realMessage.userId,
      aiID: realMessage.aiID,
      text: realMessage.text,
      isFromUser: realMessage.isFromUser,
      timestamp: realMessage.timestamp,
      englishText: realMessage.englishText,
      tip: realMessage.tip,
      followUp: realMessage.followUp,
      isLoading: false,
      replacesId: thinkingId,
    );
    _controller.add(tagged);
  }

  void dispose() {
    _controller.close();
  }
}