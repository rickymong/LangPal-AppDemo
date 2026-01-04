import 'package:flutter/material.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

class DailyChallengeTracker extends StatelessWidget {
  const DailyChallengeTracker({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(
      builder: (context, appState, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFF4D6),
                const Color(0xFFFFF8E6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Column(
            children: [
              // Trophy Icon
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC800),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              // Title
              Text(
                'Daily Challenge',
                style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),

              // Subtitle
              Text(
                'Complete 3 games to earn bonus XP',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  appState.gamesRequiredForChallenge,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                    width: screenWidth * 0.025,
                    height: screenWidth * 0.025,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < appState.gamesCompletedToday
                          ? const Color(0xFF58CC02)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}