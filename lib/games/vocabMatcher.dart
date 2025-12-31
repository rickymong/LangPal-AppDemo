import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/dailyChallengeTracker.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';
import '../types/games.dart';

class VocabMatch extends StatefulWidget{
  const VocabMatch({Key? key}) : super(key:key);
//Game game, double screenWidth, double screenHeight
  
  @override
  State<VocabMatch> createState() => _VocabMatchState();

  
}

// class _VocabMatchState extends State<VocabMatch> {

//   Map<String,String> vocabPairsMap = {};
//   List<String> vocabList = []; //map of key value pairs put into list for UI creation
//   @override
//   void initState(){
//     super.initState();
//     //get words from AI/API
//     vocabPairsMap = {"hi": "hola", "bye" : "adios", "orange" : "naranja", "meat": "carne", "chicken" : "pollo", "fat" : "gordo", "old" : "viejo"};
//     // for(String key in vocabPairsMap!.keys){ //puts list as "hi, hola, bye, adios, etc"
//     //   vocabList!.add(key);
//     //   vocabList!.add(vocabPairsMap![key]!);
//     // }
//     //puts all words into a shuffled list to be displayed
//     vocabList.addAll(vocabPairsMap.keys);
//     vocabList.addAll(vocabPairsMap.values);
//     vocabList.shuffle();

//   }

//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Vocab Match',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(screenWidth * 0.05),
//           child: Column(
//             children: [
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: vocabList.length,
//                 itemBuilder: (context, index) {
//                   return VocabCard(word: vocabList[index], screenHeight: screenHeight, screenWidth: screenWidth);
//               },
                
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class VocabCard extends StatelessWidget {
//   const VocabCard({
//     super.key,
//     required this.word,
//     required this.screenHeight,
//     required this.screenWidth,
//   });
//   final String word;
//   final double screenHeight;
//   final double screenWidth;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//     margin: EdgeInsets.only(bottom: screenHeight * 0.015),
//     padding: EdgeInsets.all(screenWidth * 0.04),
//     decoration: BoxDecoration(
//       color: const Color(0xFFF7F7F7),
//       borderRadius: BorderRadius.circular(screenWidth * 0.04),
//       border: Border.all(
//         color: const Color(0xFFE5E5E5),
//         width: 1,
//       ),
//     ),
//     child: InkWell(
//       onTap: () {
//         // Highlight green if first or correct, play audio? Red if wrong
//       },
//       child: Text(
//         word,
        
//         )
//     ),
//                 );
//   }
// }

class _VocabMatchState extends State<VocabMatch> {
  Map<String, String> vocabPairsMap = {};
  List<String> vocabList = [];
  
  String? firstSelectedWord;
  String? secondSelectedWord;
  Set<String> matchedWords = {};
  Set<String> flashingWords = {};

  @override
  void initState() {
    super.initState();
    vocabPairsMap = {
      "hi": "hola",
      "bye": "adios",
      "orange": "naranja",
      "meat": "carne",
      "chicken": "pollo",
      "fat": "gordo",
      "old": "viejo"
    };
    
    vocabList.addAll(vocabPairsMap.keys);
    vocabList.addAll(vocabPairsMap.values);
    vocabList.shuffle();
  }

  int get _matchedPairs => matchedWords.length ~/ 2;
  int get _totalPairs => vocabPairsMap.length;
  
  Color get _progressColor {
    final percentage = _matchedPairs / _totalPairs;
    if (percentage < 0.5) return Colors.red;
    if (percentage < 0.8) return const Color(0xFFD97706); // Dark yellow/amber
    return Colors.green;
  }

  void _handleCardTap(String word) {
    if (matchedWords.contains(word)) return;
    if (flashingWords.contains(word)) return;
    
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
    final first = firstSelectedWord!;
    final second = secondSelectedWord!;
    
    bool isMatch = (vocabPairsMap[first] == second) || 
                   (vocabPairsMap[second] == first);
    
    if (isMatch) {
      setState(() {
        matchedWords.add(first);
        matchedWords.add(second);
        firstSelectedWord = null;
        secondSelectedWord = null;
      });
    } else {
      setState(() {
        flashingWords.add(first);
        flashingWords.add(second);
      });
      
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          flashingWords.clear();
          firstSelectedWord = null;
          secondSelectedWord = null;
        });
      });
    }
  }

  Color _getBorderColor(String word) {
    if (flashingWords.contains(word)) return Colors.red;
    if (matchedWords.contains(word)) return Colors.green;
    if (firstSelectedWord == word || secondSelectedWord == word) {
      return Colors.green;
    }
    return const Color(0xFFE5E5E5);
  }

 @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

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
          child: Text(
            '$_matchedPairs/$_totalPairs completed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _progressColor,
            ),
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
  final bool isMatched;
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