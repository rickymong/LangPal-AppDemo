import 'dart:math';
import 'package:flutter/material.dart';
import 'package:langpal_prototype/services/ai_tutor_service.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

import '../types/chatMessage.dart';
import 'message_service.dart';

// **READ ME**
// This file contains the chat UI components:
//   - MessageBubble  : renders a single message (user or AI, with optional enriched fields)
//   - ThinkingBubble : animated "..." placeholder shown while AI is processing
//   - ChatInput      : text field + send button wired to the real AI tutor backend

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  /// Optional callback so tapping a follow-up chip pre-fills the text field.
  final void Function(String text)? onFollowUpTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onFollowUpTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return const ThinkingBubble();
    }

    final isUser = message.isFromUser;
    final bubbleColor =
        isUser ? const Color.fromARGB(255, 7, 172, 190) : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main (target-language) text
                Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                // English translation (AI only)
                if (!isUser &&
                    message.englishText != null &&
                    message.englishText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(
                    color: Colors.grey.withOpacity(0.3),
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.englishText!,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
                // Grammar tip (AI only)
                if (!isUser &&
                    message.tip != null &&
                    message.tip!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          message.tip!,
                          style: const TextStyle(
                            color: Color(0xFF07ACBE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Follow-up chip (AI only)
          if (!isUser &&
              message.followUp != null &&
              message.followUp!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: GestureDetector(
                onTap: () => onFollowUpTap?.call(message.followUp!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F8FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF07ACBE).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF07ACBE),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          message.followUp!,
                          style: const TextStyle(
                            color: Color(0xFF07ACBE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── ThinkingBubble ────────────────────────────────────────────────────────────

/// Animated "..." bubble shown while the AI is generating a response.
class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_controller.value * 3) - i).clamp(0.0, 1.0);
                final opacity = (0.4 + 0.6 * (phase < 0.5
                    ? phase * 2
                    : (1 - phase) * 2)).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: Opacity(
                    opacity: opacity,
                    child: const _Dot(),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF07ACBE),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── ChatInput ─────────────────────────────────────────────────────────────────

class ChatInput extends StatefulWidget {
  final AiPartner aiPartner;
  /// Called when the AI returns a follow-up chip — pre-fills the field.
  final TextEditingController? externalController;

  const ChatInput({
    super.key,
    required this.aiPartner,
    this.externalController,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _aiTutorService = AiTutorService();
  late TextEditingController _textController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textController =
        widget.externalController ?? TextEditingController();
  }

  /// Send the user's message and get the AI reply.
  Future<void> _handleSend(UserNotifier userNotifier) async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final userId = userNotifier.user?.id ?? 'guest';

    // 1. Show user's message immediately
    final userMsg = ChatMessage(
      id: Random().nextInt(1 << 30),
      userId: userId,
      aiID: widget.aiPartner.id,
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );
    userNotifier.addMessage(widget.aiPartner, userMsg);
    MessageService().sendMessage(userMsg);
    _textController.clear();
    setState(() => _isSending = true);

    // 2. Show a "thinking" placeholder
    final thinkingId = -(Random().nextInt(1 << 30));
    final thinkingMsg = ChatMessage(
      id: thinkingId,
      userId: userId,
      aiID: widget.aiPartner.id,
      text: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    MessageService().sendMessage(thinkingMsg);

    // 3. Call the Gemini API
    try {
      final response = await _aiTutorService.chat(
        userId: userId,
        userText: text,
        language: widget.aiPartner.language,
        history: userNotifier.conversations[widget.aiPartner] ?? [],
      );

      // 4. Replace the thinking bubble with the real reply
      final aiMsg = ChatMessage(
        id: Random().nextInt(1 << 30),
        userId: userId,
        aiID: widget.aiPartner.id,
        text: response.targetText,
        isFromUser: false,
        timestamp: DateTime.now(),
        englishText: response.englishText,
        tip: response.tip,
        followUp: response.followUp,
      );
      MessageService().replaceThinking(thinkingId, aiMsg);
      userNotifier.addMessage(widget.aiPartner, aiMsg);
    } catch (e, stackTrace) {
      print("[ChatInput] Error calling AI tutor: $e");
      print(stackTrace);
      // Replace thinking with a user-friendly error
      final errMsg = ChatMessage(
        id: Random().nextInt(1 << 30),
        userId: userId,
        aiID: widget.aiPartner.id,
        text: "Hmm, I couldn't connect to the AI tutor right now. Error: $e",
        isFromUser: false,
        timestamp: DateTime.now(),
      );
      MessageService().replaceThinking(thinkingId, errMsg);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) {
                final userNotifier =
                    context.read<UserNotifier>();
                _handleSend(userNotifier);
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isSending
                ? Colors.grey[300]
                : const Color.fromARGB(255, 7, 172, 190),
            radius: 24,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Consumer<UserNotifier>(
                    builder: (context, userNotifier, _) => IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                      onPressed: () => _handleSend(userNotifier),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Only dispose if we created it (not if it was passed in externally)
    if (widget.externalController == null) {
      _textController.dispose();
    }
    super.dispose();
  }
}