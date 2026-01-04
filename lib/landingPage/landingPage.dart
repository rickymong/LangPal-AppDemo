import 'package:flutter/material.dart';
import 'package:langpal_prototype/userAuth/accountSetup.dart/firstLangSelect.dart';
import '../userAuth/login/loginPage.dart';
import '../userAuth/accountSetup.dart/signupPage.dart';
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255), //add logic for darkmode
      body: SafeArea(
        child: Center( //wrap with scrollview?
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 600 : screenWidth
              ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //SizedBox(height: screenHeight * 0.02),
                  // Animated Image
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animation.value),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      //borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/langpal_logos/LangPal-Primary-mascot.png',
                        height: screenHeight * 0.25, //image size
                        fit: BoxFit.contain, //keeps the whole logo visable
                      ),
                    ),
                  ),
                  //SizedBox(height: screenHeight * 0.01),
                  // Title
                  Text(
                    'LangPal',
                    style: TextStyle(
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Subtitle
                  Text(
                    'Learn languages naturally through AI conversations',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  // Info Box
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Row 1
                        _buildInfoRow(
                          screenWidth,
                          'assets/langpal_logos/LangPal-Primary-mascot.png',
                          'AI Tutors',
                          'Talk to realistic AI characters',
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // Row 2
                        _buildInfoRow(
                          screenWidth,
                          'assets/langpal_logos/LangPal-Primary-mascot.png',
                          'Fun Games',
                          'Master vocabulary through play',
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // Row 3
                        _buildInfoRow(
                          screenWidth,
                          'assets/langpal_logos/LangPal-Primary-mascot.png',
                          'Track Progress',
                          'See your improvements daily',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirstLangSelectPage(), //SignUpPage
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 48, 186, 202),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  // Sign In Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailEntryPage(),
                        ),
                      );
                    },
                    // style: OutlinedButton.styleFrom(
                    //   foregroundColor: Colors.blue,
                    //   padding: const EdgeInsets.symmetric(vertical: 16),
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   side: const BorderSide(color: Colors.blue, width: 2),
                    // ),
                    child: const Text(
                      textAlign: TextAlign.center,
                      'I already have an account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                      textAlign: TextAlign.center,
                      'Free to start | Premium features available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(double screenWidth, String imgPath, String title, String subtitle) {
    return Row(
      children: [
        // Icon/Image placeholder
        Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
              imgPath,
              height: 60,
            ),
        ),
        SizedBox(width: screenWidth * 0.04),
        // Text and Subtext
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}