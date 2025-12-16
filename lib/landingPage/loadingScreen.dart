import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../types/user_notifier.dart';



class LoadingScreen extends StatefulWidget {
  static String id = 'loading_screen';
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {


  @override
  Widget build(BuildContext context) {

    final user = context.watch<UserNotifier>().user;
    // No need for FutureBuilder if bills are already available
    //if not waiting on data to load into app, run Scaffold
    return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
      //else
      //return next page
  }
}