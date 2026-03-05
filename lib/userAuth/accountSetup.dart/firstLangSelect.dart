import 'package:flutter/material.dart';
import 'package:langpal_prototype/userAuth/accountSetup.dart/goalSelection.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

class FirstLangSelectPage extends StatefulWidget {
  const FirstLangSelectPage({super.key});

  @override
  State<FirstLangSelectPage> createState() => _FirstLangSelectPageState();
}

class _FirstLangSelectPageState extends State<FirstLangSelectPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedIndex;

  List<String> languageList = ["German", "Spanish", "Japanese"];
  List flagImagePaths = ["assets/flags/german_flag.jpg", "assets/flags/spain_flag.jpg", "assets/flags/japan_flag.png"];
  //  ^ change to be country abbreviations using https://pub.dev/packages/country_flags
  
  @override
  void dispose() {
    super.dispose();
  }

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
              SizedBox(height: screenHeight * 0.1),
              const Text(
                'What do you want to learn first?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, // Slightly taller than wide for image + text
                  ),
                  itemCount: languageList.length,
                  itemBuilder: (context, index) {
                    return Consumer<UserNotifier>(
                      builder: (context, userNotifier, child){
                        return LangSelectTab(
                        language: languageList[index],
                        flagPath: flagImagePaths[index],
                        isSelected: _selectedIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            userNotifier.selectedLanguage = languageList[index];
                          });
                        },
                       );
                      }                      
                    );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalPage(), //SignUpPage
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

class LangSelectTab extends StatefulWidget {
  const LangSelectTab({
    super.key,
    required this.language,
    required this.flagPath,
    required this.isSelected,
    required this.onTap,
    this.numLearners,
  });

  final String language;
  final String flagPath;
  final bool isSelected;
  final VoidCallback onTap;
  final int? numLearners;

  @override
  State<LangSelectTab> createState() => _LangSelectTabState();
}

class _LangSelectTabState extends State<LangSelectTab> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        print('Tapped: ${widget.language}');
        // Optionally navigate after selection
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => GoalPage(),
        //   ),
        // );
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            Image.asset(
              widget.flagPath,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            // Text
            Text(
              widget.language,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}