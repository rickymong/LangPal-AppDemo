import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "types/user_notifier.dart";
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
      home: const LandingPage(),
    );
  }
}
