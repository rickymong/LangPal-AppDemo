import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';


import '../types/chatMessage.dart';
import 'chatInterface.dart';
import 'message_service.dart'; // For simple parsing
import '../types/user.dart';
import '../userNotifier.dart';

//Overall chat page, user arrives after tapping on a partner -- displays the chat UI (chat logic in chat_interface.dart)
class ChatPage extends StatefulWidget{

  final AiPartner aiPartner;

  const ChatPage({super.key, required this.aiPartner});
  @override
  State<ChatPage> createState() => _ChatPage();

}

class _ChatPage extends State<ChatPage>{
  TextEditingController chatInput = TextEditingController();
  bool isLoading = true;
  late StreamSubscription<ChatMessage> _subscription;
  final StreamController<ChatMessage> messageController = StreamController<ChatMessage>.broadcast(); //establishes a pipe from sending and receiving messages into the chat UI
  final ScrollController _scrollController = ScrollController();
  //ChatBox dummy/starter Data
    final List<ChatMessage> _messages = [
    ChatMessage(
      id: 1,
      userId: "1",
      aiID: "1",
      text: "Hello! How can I help you today?",
      isFromUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    )
  ];

  @override
  void initState(){
    super.initState();
    //load conversations from state - later from DB?
    User user = Provider.of<UserNotifier>(context, listen: false).user!;
    if(user.conversations != null){
      _messages.addAll(user.conversations?[widget.aiPartner] ?? []);
    }
    _subscription = MessageService().messageStream.listen((message){ //establishes the listening end of the message receiver
      setState((){
        _messages.add(message);
        isLoading = false;
      });
    });
    setState(() {
      isLoading = false;
    });
  }
  @override
  void dispose(){
    _scrollController.dispose();
    _subscription.cancel();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final screenWidth = size.width;
  final screenHeight = size.height;
  
  final String language =  widget.aiPartner.language[0].toUpperCase() + widget.aiPartner.language.substring(1);
  return (isLoading == true || _messages.isEmpty)
      ? Scaffold(
          appBar: AppBar(title: Text('Conversation Loading')),
          body: Center(child: CircularProgressIndicator()),
        )
      : Scaffold(
          // appBar: AppBar(
          //   title: Text(
          //     "${widget.aiPartner.name} - $language",
          //   //  softWrap: true,
          //   maxLines: 2,
          //   overflow: TextOverflow.visible,
          //     style: GoogleFonts.nunito(
          //       textStyle: const TextStyle(
          //         fontSize: 22,
          //         fontWeight: FontWeight.w800,
          //         color: Color.fromARGB(255, 255, 255, 255),
          //        // letterSpacing: 0.5,
          //       ),
          //     ),
          //   ),
          //   backgroundColor: Color.fromARGB(255, 7, 172, 190),
          //   foregroundColor: Color.fromARGB(255, 42, 42, 42),
          // ),
          appBar: AppBar(
            title: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    "${widget.aiPartner.name} - $language",
                    style: GoogleFonts.nunito(
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                );
              },
            ),
            backgroundColor: Color.fromARGB(255, 7, 172, 190),
            foregroundColor: Color.fromARGB(255, 42, 42, 42),
          ),
          resizeToAvoidBottomInset: true,
          backgroundColor: Color.fromARGB(255, 255, 248, 233),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  physics: const BouncingScrollPhysics(),
                  reverse: true, // Makes newest messages appear at bottom
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index]; // Reverse order
                    return MessageBubble(
                      message: message.text,
                      isUser: message.isFromUser,
                    );
                  },
                ),
              ),
              // Input area - stays at bottom
              SafeArea(child: ChatInput(aiPartner: widget.aiPartner)),
            ],
          ),
        );
}

  // @override
  // Widget build(BuildContext context){
  //   final size = MediaQuery.of(context).size;
  //   final width = size.width;
  //   final height = size.height;
  //   return (isLoading == true || _messages.isEmpty) ? Scaffold(
  //       appBar: AppBar(title: Text('Conversation Loading')),
  //       body: Center(child: CircularProgressIndicator()),
  //     ): Scaffold(
  //       appBar: AppBar(
  //       title: Text(
  //         widget.aiPartner.name,
  //         style: GoogleFonts.nunito(
  //           textStyle: const TextStyle(
  //             fontSize: 26,
  //             fontWeight: FontWeight.w800,
  //             color: Color.fromARGB(255, 255, 255, 255),
  //             letterSpacing: 0.5,
  //           ),
  //         ),
  //       ),
  //       backgroundColor: Color.fromARGB(255, 7, 172, 190),
  //       foregroundColor: Color.fromARGB(255, 42, 42, 42),
  //     ),
  //       resizeToAvoidBottomInset: true,
  //       backgroundColor: Color.fromARGB(255, 255, 248, 233),
  //       body: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: <Widget>[
  //               Expanded(
  //                  child: const SizedBox(height: 8),
  //               ),
  //               ChatContainer(messages: _messages), //The box that contains the messages
  //               SizedBox(height: height * 0.08,),
  //               ChatInput(aiPartner: widget.aiPartner), //The box the user types and hits send
  //               SizedBox(height: height * 0.08,)
  //           ],
  //         ),
  //       ), 
  //     );
  // }

}