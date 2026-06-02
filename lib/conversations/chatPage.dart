import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:provider/provider.dart';

import '../types/chatMessage.dart';
import 'chatInterface.dart';
import 'message_service.dart';
import '../userNotifier.dart';

/// Overall chat page — user arrives after tapping on a partner.
/// Displays the chat UI; AI logic lives in [ChatInput] / [AiTutorService].
class ChatPage extends StatefulWidget {
  final AiPartner aiPartner;

  const ChatPage({super.key, required this.aiPartner});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isLoading = true;
  late StreamSubscription<ChatMessage> _subscription;
  final ScrollController _scrollController = ScrollController();

  /// Allows ChatPage to pre-fill the input when user taps a follow-up chip.
  final TextEditingController _inputController = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 1,
      userId: '1',
      aiID: '1',
      text: 'Hello! How can I help you today?',
      isFromUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load existing conversations from state
    final user = Provider.of<UserNotifier>(context, listen: false).user!;
    if (user.conversations != null) {
      _messages.addAll(user.conversations?[widget.aiPartner] ?? []);
    }

    _subscription = MessageService().messageStream.listen((message) {
      setState(() {
        if (message.replacesId != null) {
          // Swap the loading bubble with the real AI reply
          final idx =
              _messages.indexWhere((m) => m.id == message.replacesId);
          if (idx != -1) {
            _messages[idx] = message;
          } else {
            _messages.add(message);
          }
        } else {
          _messages.add(message);
        }
        isLoading = false;
      });
      _scrollToBottom();
    });

    setState(() => isLoading = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.aiPartner.language[0].toUpperCase() +
        widget.aiPartner.language.substring(1);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading…')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              '${widget.aiPartner.name} — $language',
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 172, 190),
        foregroundColor: const Color.fromARGB(255, 42, 42, 42),
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 255, 248, 233),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  onFollowUpTap: (followUpText) {
                    _inputController.text = followUpText;
                    // Move cursor to end
                    _inputController.selection = TextSelection.fromPosition(
                      TextPosition(offset: followUpText.length),
                    );
                  },
                );
              },
            ),
          ),
          // Input bar pinned to bottom
          SafeArea(
            child: ChatInput(
              aiPartner: widget.aiPartner,
              externalController: _inputController,
            ),
          ),
        ],
      ),
    );
  }
}