
import 'package:flutter/material.dart';
import 'package:langpal_prototype/homeWidgets/homePage.dart';
import '../services/supabase_service.dart';


class SocialLogoButtons extends StatefulWidget {
  const SocialLogoButtons({
    super.key,
  });

  @override
  State<SocialLogoButtons> createState() => _SocialLogoButtonsState();
}

class _SocialLogoButtonsState extends State<SocialLogoButtons> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = screenWidth * 0.09; // Each image takes ~9% of screen width
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
             try {
                await SupabaseService.googleSignIn();

                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Google sign-in failed: $e')),
                  );
                  print(e);
                }
              }
          },
          child: Image.asset(
            'assets/social_logos/google_logo.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}