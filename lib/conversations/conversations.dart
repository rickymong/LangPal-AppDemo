import 'package:flutter/material.dart';

import '../types/aiPartner.dart';
import 'chatPage.dart';



// ** UNUSED - 2/7/2026 **
class ConversationsPage extends StatefulWidget {

  //Creates a scrollable page of buttons that display the flag, language, and name of an AI partner. Tap to enter conversation.

  final List<AiPartner> aiList; //list of users partners
  const ConversationsPage({super.key, required this.aiList});

  @override
  State<ConversationsPage> createState() => _ConversationState();
}

class _ConversationState extends State<ConversationsPage> {

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    //load data from user state

    return Scaffold(
      
      body: SingleChildScrollView(
        child: Column(
          children: widget.aiList.map((item) {
            if(widget.aiList.isEmpty){ //Used for home page when user has no partners -- does not run on general Conversations page from Nav bar
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/langpal_logos/logo_outline.png",
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Looks like you haven't started learning Yet \nGo to Conversations to get started!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }
            return Padding( //Acts as a custom button
              padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 8),
              child: GestureDetector(
                onTap: () { //send user to a chat room with the AI
                  //debugPrint("Tapped on ${item.name}");
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(aiPartner: item),
                    ),
                  );
                },
                child: Container( //UI of the button
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(item.flag_path) as ImageProvider, //Gets flag of country origin
                      fit: BoxFit.fill, // fill the box
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3), // dark overlay for text readability
                        BlendMode.darken,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color:  Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.language,
                        style: const TextStyle(
                          color:  Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        )
                     // Image(image: AssetImage(item.flag_path) as ImageProvider)
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      backgroundColor: Color.fromARGB(255, 255, 248, 233),
    );
  }
}