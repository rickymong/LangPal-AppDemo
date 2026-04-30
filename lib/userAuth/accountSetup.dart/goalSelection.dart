import 'package:flutter/material.dart';
import 'package:langpal_prototype/userAuth/accountSetup.dart/signupPage.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({
    super.key,
  });

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final List<String> goals = ["Travel & Culture", "Business & Career", "Casual Conversation", "Academic & Formal"];

  final List<String> goalImgPaths = ["assets/flags/german_flag.jpg", "assets/flags/german_flag.jpg","assets/flags/german_flag.jpg","assets/flags/german_flag.jpg", ];

  final _formKey = GlobalKey<FormState>();

  int? _selectedIndex;

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

      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GoalTab(
              goal: goals[index],
              goalImgPath: goalImgPaths[index],
              isSelected: _selectedIndex == index,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          );
        },
      ),
    ),
              //Unfinished Grid layout - Stick with list?
              // Flexible(
              //   child: GridView.builder(
              //     shrinkWrap: true,
              //     padding: const EdgeInsets.all(16),
              //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //       crossAxisCount: 2,
              //       crossAxisSpacing: 16,
              //       mainAxisSpacing: 16,
              //       childAspectRatio: 0.85, // Slightly taller than wide for image + text
              //     ),
              //     itemCount: goals.length,
              //     itemBuilder: (context, index) {
              //       return GoalTab(goal: goals[index], goalImgPath: goalImgPaths[index], );
              //     },
              //   ),
              // ),
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
class GoalTab extends StatefulWidget {
  final String goal;
  final String goalImgPath;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalTab({
    super.key,
    required this.goal,
    required this.goalImgPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<GoalTab> createState() => _GoalTabState();
}

class _GoalTabState extends State<GoalTab> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
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
                widget.goalImgPath,
                height: 60,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            // Text and Subtext
            Text(
              widget.goal,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}