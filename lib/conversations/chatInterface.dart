import 'dart:math';
import 'package:flutter/material.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

import '../types/user.dart';
import '../types/chatMessage.dart';
import 'message_service.dart';


//**READ ME **
//this file contains multiple classes that comprise the chat logic -- feel free to separate into multiple files if this seems to big or confusing due to multiple classes


class MessageBubble extends StatelessWidget { //message UI
  final String message;
  final bool isUser; //determines color and alignment of message bubble

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Color.fromARGB(255, 7, 172, 190) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}

class ChatInput extends StatefulWidget { //Input box for chat
  final AiPartner aiPartner; //Tracks what AI the user is talking with
  const ChatInput({Key? key, required this.aiPartner}) : super(key: key);
  

  @override
  State<ChatInput> createState() => _ChatInputState();
}
class _ChatInputState extends State<ChatInput> {
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override initState(){
    super.initState();
  
  }
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  User user = context.watch<UserNotifier>().user!;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Fixed values
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, -1),
          blurRadius: 5,
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24), // Fixed value
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ), // Fixed values
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(width: 8), // Fixed value
        CircleAvatar(
          backgroundColor: Color.fromARGB(255, 7, 172, 190),
          radius: 24, // Fixed value
          child: Consumer<UserNotifier>(
            builder: (context, userNotifier, child) {
              return IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20), // Fixed size
                onPressed: () {
                  if (_textController.text.trim().isNotEmpty) {
                    setState(() {
                      List<ChatMessage> messages = _sendMessage(true, _textController.text, user.id);
                      userNotifier.addMessage(widget.aiPartner, messages[0]);
                      userNotifier.addMessage(widget.aiPartner, messages[1]);
                      _textController.clear();
                    });
                  }
                },
              );
            }
          ),
        ),
      ],
    ),
  );
}
  List<ChatMessage> _sendMessage(bool isUser, String text, String userId) { //id generation needs to be made secure
    final ChatMessage message = ChatMessage(id: Random().nextInt(1000000000), userId: userId, aiID: widget.aiPartner.id, text: text, isFromUser: isUser, timestamp: DateTime.now());
    //TODO: send message to AI and catch response - trigger waiting UI?
    
    String responseText =  "My name is ${widget.aiPartner.name} -- ${message.text}"; //default dummy response
    MessageService().sendMessage(message); //sends user's message to the UI
    
    ChatMessage response = ChatMessage(id: Random().nextInt(1000000000), userId: userId, aiID: widget.aiPartner.id, text: responseText, isFromUser: false, timestamp: DateTime.now());
    MessageService().sendMessage(response); //sends AI's message to the UI
    return [message, response];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }


}