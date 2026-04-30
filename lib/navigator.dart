import 'package:flutter/material.dart';
import '/conversations/conversations.dart';
import 'oldHome.dart';
import '/profile/profile.dart';

import 'types/aiPartner.dart';

class CustomNav extends StatelessWidget{
  final GlobalKey<NavigatorState> navKey;
  final String tab; //name of screen to pass user to
  const CustomNav({super.key, required this.navKey, required this.tab});
  
  

  @override
  Widget build(BuildContext context) {
    
    //Dummy AI partner data
    final ai = AiPartner(
      name: "Sophia",
      id: "ai_001",
      language: "Spanish",
      flag_path: "assets/flags/spain_flag.jpg",
    );
    final ai2 = AiPartner(
      name: "Akira",
      id: "ai_002",
      language: "Japanese",
      flag_path: "assets/flags/japan_flag.png",
    );

    final ai3 = AiPartner(
      name: "Johann",
      id: "ai_003",
      language: "Germany",
      flag_path: "assets/flags/german_flag.jpg",
    );
    
    List<AiPartner> aiList = [ai, ai2,ai3];

    //routes the user to the selected bottom nav bar tab
    Widget child = MyHomePage();
    if(tab == "Conversations")
      child = ConversationsPage(aiList: aiList,);
    else if(tab == "Home")
      child = MyHomePage();
    else if(tab == "Profile")
      child = Profile();

    return Navigator(
      key: navKey,
      onGenerateRoute: (routeSettings){
        return MaterialPageRoute(builder: (context) => child);
      },
    );
  }
}