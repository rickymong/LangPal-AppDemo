import 'package:flutter/material.dart';
import "package:flutter_dotenv/flutter_dotenv.dart";

import 'package:google_fonts/google_fonts.dart';
import 'package:langpal_prototype/conversations/conversations.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:langpal_prototype/services/supabase_service.dart';
import 'package:provider/provider.dart';
import 'homeWidgets/homePage.dart';
import 'types/user.dart';
import "userNotifier.dart";
import "landingPage/landingPage.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await dotenv.load(fileName: ".env");
  await SupabaseService.initialize();
  
  runApp(ChangeNotifierProvider(
    create: (context) => UserNotifier(),
    child: MyApp()
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LangPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that shows AuthPage or MyHomePage based on login state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(
      builder: (context, userNotifier, child) {
        // Show loading while initializing
        if (userNotifier.isLoading) {
          return const Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 248, 233),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 7, 172, 190),
                  ),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Show home page if user is loaded (logged in or demo mode)
        if (userNotifier.user != null) {
          return const HomeScreen(); //does this set usernotifier state?
        }

        // Show auth page if no user
        else{ return const LandingPage();}
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String _currentPage = "Home";
  List<String> pages = ["Conversations", "Home", "Profile"];
  final Map<String, GlobalKey<NavigatorState>> _navKeys = {
    "Conversations": GlobalKey<NavigatorState>(),
    "Home": GlobalKey<NavigatorState>(),
    "Profile": GlobalKey<NavigatorState>(),
  };
  
  int _index = 1;
  void _selectTab(String tabItem, int index) {
    if(tabItem == _currentPage){
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
            children: <Widget>[
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
                  aiList: user.conversations?.keys.toList() as List<AiPartner>
                  ))
              
            ],
          ),
        ),
         // _buildNav("Conversations"),
         // _buildNav("Home"),
         // _buildNav("Profile"),
        ]
      ),
    
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (int index) {_selectTab(pages[index], index); },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.message, size: 25),
            label: 'Conversations',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'images/logo_outline.png',
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
}
