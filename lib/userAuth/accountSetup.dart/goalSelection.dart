import 'package:flutter/material.dart';
import 'package:langpal_prototype/landingPage/landingPage.dart';
import 'package:langpal_prototype/userAuth/accountSetup.dart/signupPage.dart';

class GoalPage extends StatelessWidget {
  GoalPage({
    super.key,
  });

  final List<String> goals = ["Travel & Culture", "Business & Career", "Casual Conversation", "Academic & Formal"];
  final List<String> goalImgPaths = ["images/flags/german_flag.jpg", "images/flags/german_flag.jpg","images/flags/german_flag.jpg","images/flags/german_flag.jpg", ];
  final _formKey = GlobalKey<FormState>();


  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth =  MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255), //add logic for darkmode
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02),
              const Text(
                'Choose a language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
              const Text(
                'What do you want to learn first?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, // Slightly taller than wide for image + text
                  ),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return GoalTab(goal: goals[index], goalImgPath: goalImgPaths[index], );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpPage(), //SignUpPage
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 48, 186, 202),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class GoalTab extends StatelessWidget {
  const GoalTab({
    super.key,
    required this.goal,
    required this.goalImgPath
  });
  final String goal;
  final String goalImgPath;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth =  MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        // Handle tap
        //print('Tapped: $language');
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const GoalPage(),
        //   ),
        // );
      },
      child: Row(
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
              goalImgPath,
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
                goal,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
            ],
          ),
        ),
      ],
     ),
    );
  }
}
