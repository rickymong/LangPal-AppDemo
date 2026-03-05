import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:langpal_prototype/userNotifier.dart';
import 'gameTimer.dart';

class SentenceBuilder extends StatefulWidget{
  const SentenceBuilder({Key? key, required this.xp}) : super(key:key);
  final int xp;
  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder>{
  //Idea - query a series of sentences and options to make the game longer, have the timer move user to next question, each one correct adds to a score a streak.
  //Ending with a streak if X or more provides bonus xp.
  String sentence = "The boy likes to go on walks with his dog";
  String blankWord = "walks";
  int blankPosition = 6;
  List<String> options = ["walks", "swims", "flights"];
  late String blankSentence;
  String? selectedWord;

  double seconds = 5;
  bool timesUp = false;
  bool winGame = false;
  bool gameComplete = false; //a 1 time flag to avoid rerunning of win/loss condition results

  final AudioPlayer correctPlayer = AudioPlayer();
  final AudioPlayer wrongPlayer = AudioPlayer();
  

  @override
  void didUpdateWidget(SentenceBuilder oldWidget){
    super.didUpdateWidget(oldWidget);
    _checkTimeUp();
  }

  @override
  void initState() {
    super.initState();
    //format the sentence
    formatSentence();
    _preloadSounds();
  }

  @override
  void dispose() {
    correctPlayer.dispose();
    wrongPlayer.dispose();
    super.dispose();

  }
  void formatSentence(){
    List<String> words = sentence.split(" ");
    words[blankPosition] = "___";
    blankSentence = words.join(" ");
    
  }
    void _preloadSounds() async {
    await correctPlayer.setSource(AssetSource('audio/games/vocab_match_correct.wav'));
    await wrongPlayer.setSource(AssetSource('audio/games/vocab_match_incorrect.wav'));

    await correctPlayer.setReleaseMode(ReleaseMode.stop);
    await wrongPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Color _getBorderColor(String word) {
    if (selectedWord == word && word.toLowerCase() != blankWord.toLowerCase()){
      return Colors.red; //mark red if wrong
    } 
    else if (selectedWord == blankWord && blankWord == word && winGame) return Colors.green; //mark green if correct
    //else be grey (default)
    return const Color(0xFFE5E5E5);
  }
  

  void _handleCardTap(String word){
    if (gameComplete) return; //prevents changing answers once game is over

    setState(() {
      selectedWord = word;
    });
    _checkMatch();
  }
  void _checkMatch(){
    if (gameComplete) return; //prevent repeat win logic from running

    bool isMatch = selectedWord!.toLowerCase() == blankWord.toLowerCase();
    if(isMatch){
     //correctPlayer.play(AssetSource('audio/games/vocab_match_correct.wav'));
      correctPlayer.seek(Duration.zero);
      correctPlayer.resume();
     setState(() {
       winGame = true;
     });
     _completeGame(result: true);
    }
    else{
      wrongPlayer.seek(Duration.zero);
      wrongPlayer.resume();
    }
  }

  void _completeGame({required bool result}){
    if(gameComplete) return;
    gameComplete = true;
    print("game complete");
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    _showCompletionPopup(context, result);
    if(result == true){
      userNotifier.completeGame(widget.xp);
    }
    Future.delayed(const Duration(seconds: 2), (){
      if(context.mounted){
        Navigator.pop(context);
      }
    });
       //   if(context.mounted){
       // Navigator.pop(context);
     // }
  }

  void _checkTimeUp(){
    if(gameComplete) return;
    if(timesUp){
      _completeGame(result: false);
    }
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final userNotifier = context.read<UserNotifier>(); // Get it here in build

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (selectedWord == blankWord) {
    //     setState(() {
    //       //winGame = false;
    //       //selectedWord = null;
    //     });
    //     _showCompletionPopup(context, true);
    //     userNotifier.completeGame(widget.xp);
    //     // Future.delayed(const Duration(seconds: 2), () {
    //     //   if (context.mounted) {
    //     //     Navigator.pop(context);
    //     //   }
    //     // });
    //   }
    //   else if(timesUp == true){
    //     _showCompletionPopup(context, false);
    //     Future.delayed(const Duration(seconds: 2), (){
    //       if(context.mounted){
    //         Navigator.pop(context);
    //       }
    //     });
    //   }
    // });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black)),
        title: const Text(
          "Sentence Builder",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.05,
            ),
          ),
          GameTimer(seconds: seconds, onFinish: () {
                if(!mounted) return;
                //_showCompletionPopup(context, false); //change to a local function that sets a local timer variable to finished - triggering the post frame callback
                  if(winGame){
                    setState(() {
                      timesUp = true;
                    });
                  }
                  
                }),
          Row(
            children: [
              Expanded(
                child: Text(
                  blankSentence,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                ),
              ),
              SizedBox(width: screenWidth * 0.10), 
            ],
          ),
          SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, index){
                final word = options[index];
                return WordCard(word: word, screenHeight: screenHeight, screenWidth: screenWidth, borderColor: _getBorderColor(word), onTap: () => _handleCardTap(word));
              },
              )
          )
        ],
        
      ),
    );
  }
  void _showCompletionPopup(BuildContext context, bool won) {
 // _hasShownCompletion = true; // Prevent showing multiple times
  print("in popUp");
  ScaffoldMessenger.of(context).showSnackBar(
    
    SnackBar(
      content: won ? Text('Game completed! +${widget.xp} XP earned') : Text("Time's Up! Try Again!"),
      backgroundColor: won ?  Color(0xFF58CC02) :  Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
      ),
      //duration: const Duration(seconds: 2),
    ),
  );
}

}

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.screenHeight,
    required this.screenWidth,
    required this.borderColor,
    // required this.isCorrect,
    required this.onTap,
  });

  final String word;
  final double screenHeight;
  final double screenWidth;
  final Color borderColor;
//  final bool isCorrect; //if word has already been matched properly, alter color
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.025,
              horizontal: screenWidth * 0.04,
            ),
            decoration: BoxDecoration(
              // color: isCorrect 
              //     ? const Color(0xFFF0F0F0) 
              //     : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              border: Border.all(
                color: borderColor,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  // color: isCorrect 
                  //     ? Colors.grey.shade500 
                  //     : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}