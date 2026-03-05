import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/gameTimer.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../types/games.dart';

class VocabMatch extends StatefulWidget{
  const VocabMatch({Key? key, required this.xp}) : super(key:key);
//Game game, double screenWidth, double screenHeight
  final int xp;
  
  @override
  State<VocabMatch> createState() => _VocabMatchState();

  
}

class _VocabMatchState extends State<VocabMatch> {
  Map<String, String> vocabPairsMap = {};
  List<String> vocabList = [];
  
  String? firstSelectedWord;
  String? secondSelectedWord;
  Set<String> matchedWords = {};
  Set<String> flashingWords = {};

  final AudioPlayer correctPlayer = AudioPlayer();
  final AudioPlayer wrongPlayer = AudioPlayer();

  bool timeUp = false;
  double seconds = 5;
  bool gameComplete = false;
  @override
  void initState() {
    super.initState();
    vocabPairsMap = {
      "hi": "hola",
      "bye": "adios",
      //"orange": "naranja",
      //"meat": "carne",
      //"chicken": "pollo",
      //"fat": "gordo",
      //"old": "viejo"
    };
    
    vocabList.addAll(vocabPairsMap.keys);
    vocabList.addAll(vocabPairsMap.values);
    vocabList.shuffle();

    _preloadSounds();
  }

    @override
  void didUpdateWidget(VocabMatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkTimesUp(); // ✅ Check if time is up
    _checkIfWin(); // ✅ Check if all matches found
  }


  @override
  void dispose() {
    correctPlayer.dispose();
    wrongPlayer.dispose();
    super.dispose();

  }

  int get _matchedPairs => matchedWords.length ~/ 2;
  int get _totalPairs => vocabPairsMap.length;
  
  Color get _progressColor {
    final percentage = _matchedPairs / _totalPairs;
    if (percentage < 0.5) return Colors.red;
    if (percentage < 0.8) return const Color(0xFFD97706); // Dark yellow/amber
    return Colors.green;
  }
  void _preloadSounds() async {
    await correctPlayer.setSource(AssetSource('audio/games/vocab_match_correct.wav'));
    await wrongPlayer.setSource(AssetSource('audio/games/vocab_match_incorrect.wav'));

    await correctPlayer.setReleaseMode(ReleaseMode.stop);
    await wrongPlayer.setReleaseMode(ReleaseMode.stop);
  }
  
  void _handleCardTap(String word) {
    if (gameComplete) return;
    if (matchedWords.contains(word) || flashingWords.contains(word)) return;
    
    setState(() {
      if (firstSelectedWord == null) {
        firstSelectedWord = word;
      } else if (firstSelectedWord == word) {
        firstSelectedWord = null;
      } else if (secondSelectedWord == null) {
        secondSelectedWord = word;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if(gameComplete) return;
    final first = firstSelectedWord!;
    final second = secondSelectedWord!;
    
    bool isMatch = (vocabPairsMap[first] == second) || (vocabPairsMap[second] == first);
    
    if (isMatch) {
     // correctPlayer.seek(Duration.zero);
     // correctPlayer.resume;
     correctPlayer.play(AssetSource('audio/games/vocab_match_correct.wav'));
      setState(() {
        matchedWords.add(first);
        matchedWords.add(second);
        firstSelectedWord = null;
        secondSelectedWord = null;
      });
      _checkIfWin();
    } else {
      wrongPlayer.seek(Duration.zero);
      wrongPlayer.resume();
      setState(() {
        flashingWords.add(first);
        flashingWords.add(second);
      });
      
      Future.delayed(const Duration(milliseconds: 600), () { //has cards appear red
        setState(() {
          flashingWords.clear();
          firstSelectedWord = null;
          secondSelectedWord = null;
        });
        if(matchedWords.length == vocabList.length){

        }
      });
    }
    print("matchWords: ${matchedWords.length}");
    print("vocabList: ${vocabList.length}");
  }

   void _checkIfWin() {
    if (gameComplete) return;
    
    if (matchedWords.length == vocabList.length) {
      _completeGame(won: true);
    }
  }

  void _checkTimesUp() {
    if (gameComplete) return;
    
    if (timeUp) {
      _completeGame(won: false);
    }
  }

  void _completeGame({required bool won}) {
    if (gameComplete) return;
    
    gameComplete = true;
    
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    
    if (won) {
      userNotifier.completeGame(widget.xp);
    }
    
    _showCompletionPopup(context);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  Color _getBorderColor(String word) {
    if (flashingWords.contains(word)) return Colors.red; //if pair is wrong
    if (matchedWords.contains(word)) return Colors.green; //highlight proper matches
    if (firstSelectedWord == word || secondSelectedWord == word) { //highlight currently selected word
      return Colors.green;
    }
    return const Color(0xFFE5E5E5);
  }

 @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final userNotifier = context.read<UserNotifier>(); // Get it here in build

//  WidgetsBinding.instance.addPostFrameCallback((_) {
//     if (matchedWords.length == vocabList.length) {
//       _showCompletionPopup(context);
//       userNotifier.completeGame(widget.xp);
//       Future.delayed(const Duration(seconds: 2), () {
//         if (context.mounted) {
//           Navigator.pop(context);
//         }
//       });
//         }
//     });
  
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Vocab Match',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: Column(
      children: [
        // Progress Counter - centered text above scroll view
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.05,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_matchedPairs/$_totalPairs completed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _progressColor,
                ),
              ),
              SizedBox(width: screenWidth * 0.10),
              GameTimer(seconds: seconds, onFinish: () {
                if(!mounted) return;

                if(!gameComplete) showTimesUpModal(context: context, score: _matchedPairs, total: _totalPairs);
                }) //onFinish: () {_showTimesUpPopup(context, _matchedPairs, _totalPairs); }
            ],
          ),
        ),
        
        // Scrollable vocab cards
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vocabList.length,
                itemBuilder: (context, index) {
                  final word = vocabList[index];
                  return VocabCard(
                    word: word,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    borderColor: _getBorderColor(word),
                    isMatched: matchedWords.contains(word),
                    onTap: () => _handleCardTap(word),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _showCompletionPopup(BuildContext context) {
 // _hasShownCompletion = true; // Prevent showing multiple times
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Game completed! +${widget.xp} XP earned'),
      backgroundColor: const Color(0xFF58CC02),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void showTimesUpModal({
  required BuildContext context,
  required int score,
  required int total
}) {
  bool popped = false;

  void exitFlow() {
    if (popped) return;
    popped = true;

    Navigator.of(context).pop(); // close modal
    Navigator.of(context).pop(); // pop game screen
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      // Auto-exit after 5 seconds
      Future.delayed(const Duration(seconds: 5), exitFlow);

      return AlertDialog(
        title: const Text(
          "Time’s Up!",
          textAlign: TextAlign.center,
        ),
        content: Text(
          "Score: $score / $total",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: exitFlow,
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}



}



class VocabCard extends StatelessWidget {
  const VocabCard({
    super.key,
    required this.word,
    required this.screenHeight,
    required this.screenWidth,
    required this.borderColor,
    required this.isMatched,
    required this.onTap,
  });

  final String word;
  final double screenHeight;
  final double screenWidth;
  final Color borderColor;
  final bool isMatched; //if word has already been matched properly, alter color
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
              color: isMatched 
                  ? const Color(0xFFF0F0F0) 
                  : const Color(0xFFF7F7F7),
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
                  color: isMatched 
                      ? Colors.grey.shade500 
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

