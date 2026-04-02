import 'package:flutter/material.dart';
import 'package:langpal_prototype/audio_tutor/call_screen.dart';
import 'package:langpal_prototype/profile/profile.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';
import '../text_tutor/chatPage.dart';
import '../games/gamesPage.dart';
import '../types/lesson.dart';
import 'progressBar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDarkMode = false;

  // Sample lessons data
  final List<Lesson> lessons = [
    Lesson(
      name: 'Basic Greetings',
      progress: 0.6,
      xp: 60,
      lessonType: 'Completed',
      icon: Icons.waving_hand,
    ),
    Lesson(
      name: 'Introducing Yourself',
      progress: 0.4,
      xp: 30,
      lessonType: 'In Progress',
      icon: Icons.person,
    ),
    Lesson(
      name: 'Common Phrases',
      progress: 0.3,
      xp: 20,
      lessonType: 'In Progress',
      icon: Icons.chat_bubble_outline,
    ),
    Lesson(
      name: 'Numbers & Time',
      progress: 0.0,
      xp: 0,
      lessonType: 'Not started',
      icon: Icons.access_time,
    ),
    Lesson(
      name: 'Food & Dining',
      progress: 0.0,
      xp: 0,
      lessonType: 'Locked',
      icon: Icons.restaurant,
    ),
    Lesson(
      name: 'Travel Essentials',
      progress: 0.0,
      xp: 0,
      lessonType: 'Locked',
      icon: Icons.luggage,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<UserNotifier>(
      builder: (context, userNotifier, child) {
        // Show loading if data is still loading
        if (userNotifier.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show your actual home screen content
        return Scaffold(
          backgroundColor: _isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: screenHeight * 0.04),
                    _buildStatsRow(),
                    SizedBox(height: screenHeight * 0.04),
                    DailyProgress(isDarkMode: _isDarkMode),
                    SizedBox(height: screenHeight * 0.04),
                    _buildQuickActions(),
                    SizedBox(height: screenHeight * 0.04),
                    _buildLessonsSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        // Parrot icon (using emoji in a container for visual)
        GestureDetector(
          onTap: () => {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Profile()))
          },
          child: Container(
            width: screenWidth * 0.175,
            height: screenWidth * 0.175,
            // decoration: BoxDecoration(
            //   gradient: const LinearGradient(
            //     colors: [Color(0xFF58CC02), Color(0xFF89E219)],
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //   ),
            //   borderRadius: BorderRadius.circular(12),
            // ),
            // child: const Center(
            //   child: Text(
            //     '🦜',
            //     style: TextStyle(fontSize: 28),
            //   ),
            // ),
            child: Image.asset(
              'assets/langpal_logos/LangPal-Primary-mascot.png',
              //height: screenHeight * 0.25, //image size
              fit: BoxFit.contain, //keeps the whole logo visable
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Keep up the great work',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const Spacer(),
        // Dark mode toggle
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Expanded(
          child: Consumer<UserNotifier>(
            builder: (context, appState, child) {
              return StatBox(
                  isDarkMode: _isDarkMode,
                  icon: Icons.local_fire_department,
                  value: '${appState.user?.streak ?? -2}',
                  label: 'Day Streak',
                  iconColor: const Color(0xFFFF9600),
                  backgroundColor: const Color(0xFFFFF4E5));
            },
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Consumer<UserNotifier>(
            builder: (context, appState, child) {
              return StatBox(
                  isDarkMode: _isDarkMode,
                  icon: Icons.emoji_events,
                  value: '${appState.totalXP}',
                  label: 'Total XP',
                  iconColor: const Color(0xFFFFC800),
                  backgroundColor: const Color(0xFFFFFBE6));
            },
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Consumer<UserNotifier>(
            builder: (context, appState, child) {
              return StatBox(
                  isDarkMode: _isDarkMode,
                  icon: Icons.radio_button_checked,
                  value: '${appState.currentDailyXP}/${appState.dailyGoal}',
                  label: 'Daily Goal',
                  iconColor: const Color(0xFF58CC02),
                  backgroundColor: const Color(0xFFE7F5E0));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    AiPartner dummyPartner = AiPartner(
        name: "Johnson",
        id: "999",
        language: "Spanish",
        flag_path: "assets/flags/spain_flag.jpr");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.school,
                label: 'AI Tutor',
                subtitle: 'Practice conversation',
                backgroundColor: const Color(0xFFE0F4FF),
                iconColor: const Color(0xFF1CB0F6),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(aiPartner: dummyPartner),
                      ));
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.videogame_asset,
                label: 'Games',
                subtitle: 'Fun challenges',
                backgroundColor: const Color(0xFFFFF4E5),
                iconColor: const Color(0xFFFF9600),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GamesPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.mic,
                label: 'Pronunciation',
                subtitle: 'Improve accent',
                backgroundColor: const Color(0xFFFFE8E8),
                iconColor: const Color(0xFFFF4B4B),
                onTap: () {
                  // Handle Pronunciation tap
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.bolt,
                label: 'Quick Practice',
                subtitle: '5 min review',
                backgroundColor: const Color(0xFFE7F5E0),
                iconColor: const Color(0xFF58CC02),
                onTap: () {
                  // Handle Quick Practice tap
                },
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        _buildCallActionButton(
            icon: Icons.phone,
            label: "Live Practice",
            subtitle: "have a real conversation with AI",
            backgroundColor: const Color.fromARGB(255, 49, 55, 80),
            iconColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CallScreen(
                    characterName: "Robot",
                    language: "Spanish",
                  ),
                ),
              );
            }
        )
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2A2A2A) : backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(height: screenHeight * 0.03),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: screenWidth * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2A2A2A) : backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(height: screenHeight * 0.03),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Lessons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: screenHeight * 0.04),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            return _buildLessonCard(lessons[index]);
          },
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final bool isLocked = lesson.lessonType == 'Locked';
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLocked
                  ? (_isDarkMode
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFFE5E5E5))
                  : const Color(0xFFE7F5E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked ? Icons.lock : lesson.icon,
              color: isLocked
                  ? (_isDarkMode ? Colors.grey[600] : Colors.grey[400])
                  : const Color(0xFF58CC02),
              size: 24,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          // Lesson details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (!isLocked) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${lesson.xp} XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isLocked) ...[
                  SizedBox(height: screenHeight * 0.02),
                  ProgressBar(
                    progress: lesson.progress,
                    height: 6,
                    backgroundColor: _isDarkMode
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE5E5E5),
                    progressColor: const Color(0xFF58CC02),
                  ),
                ] else ...[
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    lesson.lessonType,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Icon(
            Icons.chevron_right,
            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }
}

class DailyProgress extends StatelessWidget {
  const DailyProgress({
    super.key,
    required bool isDarkMode,
  }) : _isDarkMode = isDarkMode;

  final bool _isDarkMode;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer<UserNotifier>(
      builder: (context, appState, child) {
        // Calculate progress as fraction
        double progressFraction = appState.currentDailyXP / appState.dailyGoal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${appState.currentDailyXP} / ${appState.dailyGoal} XP',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            ProgressBar(
              progress: progressFraction,
              height: 12,
              backgroundColor: const Color.fromARGB(255, 197, 194, 194),
              // _isDarkMode ? const Color.fromARGB(255, 117, 117, 117) : const Color(0xFFE5E5E5),
              progressColor: const Color(0xFF58CC02),
            ),
          ],
        );
      },
    );
  }
}

class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required bool isDarkMode,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
  }) : _isDarkMode = isDarkMode;

  final bool _isDarkMode;
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          SizedBox(height: screenHeight * 0.02),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
