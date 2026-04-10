import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/dailyChallengeTracker.dart';
import 'package:langpal_prototype/games/sentenceBuilder.dart';
import 'package:langpal_prototype/games/speedVocab.dart';
import 'package:langpal_prototype/games/grammarQuest.dart';
import 'package:langpal_prototype/games/vocabMatcher.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';
import '../types/games.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  // Sample games data
  final List<Game> games = [
    Game(
      name: 'Word Match',
      xp: 20,
      time: 3,
      difficulty: 'Easy',
      icon: Icons.extension,
      summary: 'Match words with translations',
      gamePage: VocabMatch(xp: 20) //decouple link from Game?
    ),
    Game(
      name: 'Sentence Builder',
      xp: 30,
      time: 5,
      difficulty: 'Medium',
      icon: Icons.view_module,
      summary: 'Build sentences from words',
      gamePage: SentenceBuilder(xp: 30)
    ),
    Game(
      name: 'Speed Vocab',
      xp: 15,
      time: 2,
      difficulty: 'Easy',
      icon: Icons.bolt,
      summary: 'Quick vocabulary challenges',
      gamePage: SpeedVocab(xp: 15),
    ),
    Game(
      name: 'Grammar Quest',
      xp: 40,
      time: 7,
      difficulty: 'Hard',
      icon: Icons.edit_note,
      summary: 'Master grammar rules',
      gamePage: GrammarQuest(xp: 40),
    ),
    Game(
      name: 'Listening Challenge',
      xp: 35,
      time: 6,
      difficulty: 'Medium',
      icon: Icons.headphones,
      summary: 'Test your listening skills',
    ),
  ];

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
          'Language Games',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Challenge Section
              DailyChallengeTracker(screenWidth: screenWidth, screenHeight: screenHeight),
              SizedBox(height: screenHeight * 0.03),

              // Choose a Game Section
              Text(
                'Choose a Game',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Games List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return _buildGameCard(
                    games[index],
                    screenWidth,
                    screenHeight,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(Game game, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Handle game tap - navigate to game screen
          if(game.gamePage != null){
            print("=====================has gamepage");
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => game.gamePage!),
            );
          }
          else{
            print("NO GAMEPAGE");
          _showGameStartDialog(game, screenWidth, screenHeight);
          }
        },
        child: Row(
          children: [
            // Game Icon
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(game.difficulty),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Icon(
                game.icon,
                color: _getIconColor(game.difficulty),
                size: screenWidth * 0.06,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),

            // Game Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Name and Difficulty Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.name,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyBackgroundColor(game.difficulty),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Text(
                          game.difficulty,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: _getDifficultyTextColor(game.difficulty),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.005),

                  // Summary
                  Text(
                    game.summary,
                    style: TextStyle(
                      fontSize: screenWidth * 0.033,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),

                  // XP and Time
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: screenWidth * 0.035,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        '${game.xp} XP',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Icon(
                        Icons.access_time,
                        size: screenWidth * 0.035,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        '${game.time} min',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),

            // Chevron Icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: screenWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get icon background color based on difficulty
  Color _getIconBackgroundColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFFE0F4FF);
      case 'medium':
        return const Color(0xFFE7F5E0);
      case 'hard':
        return const Color(0xFFFFE8E8);
      default:
        return const Color(0xFFE5E5E5);
    }
  }

  // Helper method to get icon color based on difficulty
  Color _getIconColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF1CB0F6);
      case 'medium':
        return const Color(0xFF58CC02);
      case 'hard':
        return const Color(0xFFFF4B4B);
      default:
        return Colors.grey;
    }
  }

  // Helper method to get difficulty badge background color
  Color _getDifficultyBackgroundColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFFE0F4FF);
      case 'medium':
        return const Color(0xFFD7F4E3);
      case 'hard':
        return const Color(0xFFFFDCDC);
      default:
        return const Color(0xFFE5E5E5);
    }
  }

  // Helper method to get difficulty badge text color
  Color _getDifficultyTextColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF1CB0F6);
      case 'medium':
        return const Color(0xFF58CC02);
      case 'hard':
        return const Color(0xFFFF4B4B);
      default:
        return Colors.grey;
    }
  }

  // Dialog to simulate starting a game (for demo purposes)
  void _showGameStartDialog(Game game, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        title: Text(
          game.name,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game.summary,
              style: TextStyle(fontSize: screenWidth * 0.035),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Icon(Icons.stars, size: screenWidth * 0.04, color: Colors.grey),
                SizedBox(width: screenWidth * 0.02),
                Text('Earn ${game.xp} XP'),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Icon(Icons.access_time, size: screenWidth * 0.04, color: Colors.grey),
                SizedBox(width: screenWidth * 0.02),
                Text('${game.time} minutes'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate game completion
              _simulateGameCompletion(game);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
            ),
            child: Text(
              'Start Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simulate game completion for demo purposes
  void _simulateGameCompletion(Game game) {
    // In a real app, this would be called after the game is actually completed
    final appState = Provider.of<UserNotifier>(context, listen: false);
    appState.completeGame(game.xp);

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Game completed! +${game.xp} XP earned'),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
        ),
      ),
    );
  }
}
