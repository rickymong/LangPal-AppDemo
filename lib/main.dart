import 'package:flutter/material.dart';
import 'package:langpal_prototype/homeWidgets/homePage.dart';
import 'package:provider/provider.dart';
import "userNotifier.dart";
import "landingPage/landingPage.dart";


void main() {
  
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
      home: const HomeScreen(),
      //home: const LandingPage(),
    );
  }
}
