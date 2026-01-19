import 'dart:async';

import 'package:flutter/material.dart';

class GameTimer extends StatefulWidget{
  const GameTimer({Key? key, required this.seconds, this.onFinish}) : super(key:key);
  final double seconds;
  final VoidCallback? onFinish;
  @override
  State<GameTimer> createState() => _GameTimerState();
}
class _GameTimerState extends State<GameTimer>{
  late Timer _timer;
  late double time = 50; //grab Widget.seconds when started
  late double threshold;
  void startTimer(){
    time = widget.seconds;
    threshold = time * 0.2;
    _timer = Timer.periodic(Duration(seconds: 1), (timer){
      if(time == 0){
        setState(() {
          timer.cancel();
          print("====== TIMER DONE =======");
          if(widget.onFinish != null)
            widget.onFinish!();
        });
      }
      else{
        setState(() {
          time --;
        });
      }
    });
  }

  @override
  @override
  void initState() {
    super.initState();
    startTimer();
  }
  @override
  void dispose(){
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time.toInt().toString(),
        style:  TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: (time > threshold) ? Colors.black : Colors.red
        ),
      ),
    );
  }
}