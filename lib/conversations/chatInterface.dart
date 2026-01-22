import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:langpal_prototype/landingPage/loadingScreen.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

import '../types/user.dart';
import '../types/chatMessage.dart';
import 'message_service.dart';


//**READ ME **
//this file contains multiple classes that comprise the chat logic -- feel free to separate into multiple files if this seems to big or confusing due to multiple classes

class ChatContainer extends StatefulWidget { //Container that holds the messages
  List<ChatMessage> messages;
   ChatContainer({
    super.key, 
    required this.messages,
  });

@override
  State<ChatContainer> createState() => _ChatContainer();
}
class _ChatContainer extends State<ChatContainer>{
  final ScrollController? scrollController = ScrollController();
  //late StreamSubscription<ChatMessage> _subscription;
 
  @override
void initState() {
  super.initState();

}

@override
void dispose(){
 // _subscription.cancel();
  scrollController?.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 50,
        maxHeight: 500,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: widget.messages.length,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final message = widget.messages[index];
            return MessageBubble(
              message: message.text,
              isUser: message.isFromUser,
            );
          },
        ),
      ),
    );
  }
}

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
  //String userId = context.read<UserNotifier>().user!.id;
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  User user = context.watch<UserNotifier>().user!; //gets user info - triggers refresh if state updates
  return Container(
    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.01),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black,
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
                borderRadius: BorderRadius.circular(screenWidth * 0.06),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.012,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        CircleAvatar(//send button
          backgroundColor: Color.fromARGB(255, 7, 172, 190),
          radius: screenWidth * 0.06,
          child: Consumer<UserNotifier>(
            builder: (context, userNotifier, child){
            return IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: screenWidth * 0.05),
              onPressed: () {
                // Send message logic
                if (_textController.text.trim().isNotEmpty) {
                  setState(() {
                    //send new message object to list of messages in ChatContainer;
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