import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langpal_prototype/conversations/conversations.dart';
import 'package:langpal_prototype/navigator.dart';
import 'package:langpal_prototype/profile/profile.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:provider/provider.dart';
import 'types/user.dart';
import "userNotifier.dart";


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String _currentPage = "Home";
  List<String> pages = ["Conversations", "Home", "Profile"];
  final Map<String, GlobalKey<NavigatorState>> _navKeys = { //names of screens in nav bar
    "Conversations": GlobalKey<NavigatorState>(),
    "Home": GlobalKey<NavigatorState>(),
    "Profile": GlobalKey<NavigatorState>(),
  };
  
  int _index = 1;
  void _selectTab(String tabItem, int index) { //custom nav bar selecting method
    if(tabItem == _currentPage){ //
      _navKeys[tabItem]?.currentState?.popUntil((route) => route.isFirst);
    }
    else{
      setState(() {
        _currentPage = pages[index];
        _index = index;
      });
    }
    print("going to page #$index, name= $tabItem");
    }

  @override
  Widget build(BuildContext context) {
    User user = context.read<UserNotifier>().user!;
    //print(user.conversations!.keys.toList()[0].name ?? "List is null" );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPage,
          style: GoogleFonts.nunito(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 255, 255, 255),
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 7, 172, 190),
        foregroundColor: Color.fromARGB(255, 42, 42, 42),
      ),
      
      body: Stack(
        children: <Widget>[
          Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[ //List of current AI partners for languages being learned
              SizedBox(height: 10),
              Text(
                "Your Conversations",
                style: GoogleFonts.nunito(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 0, 0, 0),
                    letterSpacing: 0.5,
                  ),
                ),
                ),
              Expanded(
                child: ConversationsPage(
                  aiList: user.conversations?.keys.toList() as List<AiPartner> //create a list of AI partners based on what languages the user is learning
                  ))
              
            ],
          ),
        ),
        //establishes that the other nav bar pages exist -- this may be a poor way of doing so, I am open to revisiting this
          _buildNav("Conversations"),
         // _buildNav("Home"),
          _buildNav("Profile"),
        ]
      ),
    
      bottomNavigationBar: BottomNavigationBar( //Custom nav bar
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (int index) {_selectTab(pages[index], index); }, //directs user to new page
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.message, size: 25),
            label: 'Conversations',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/langpal_logos/logo_outline.png',
              height: 60,
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 25),
            label: 'Settings',
          ),
        ],
        selectedItemColor: const Color.fromARGB(150, 6, 172, 191),
        backgroundColor: Color.fromARGB(255, 255, 248, 233),
      ),
      backgroundColor: Color.fromARGB(255, 255, 248, 233),
      
    
    );
  }
  Widget _buildNav(String targetTab){
    return Offstage(
      offstage: _currentPage != targetTab,
      child: CustomNav(navKey: _navKeys[targetTab]!, tab: targetTab)
    );
  }
}//end _MyHomePageState