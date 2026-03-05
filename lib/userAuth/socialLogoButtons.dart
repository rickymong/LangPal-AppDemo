import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:langpal_prototype/homeWidgets/homePage.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final imageSize = screenWidth * 0.12; // Each image takes ~12% of screen width
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            print("apple");
          },
          child: Image.asset(
            'assets/social_logos/icons8-apple-logo-50-2.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
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
            'assets/social_logos/icons8-gmail-50-3.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        GestureDetector(
          onTap: () {
            print("instagram");
          },
          child: Image.asset(
            'assets/social_logos/icons8-instagram-50.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        GestureDetector(
          onTap: () {
            print("X");
          },
          child: Image.asset(
            'assets/social_logos/icons8-x-logo-50-2.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        GestureDetector(
          onTap: () {
            print("facebook");
          },
          child: Image.asset(
            'assets/social_logos/icons8-facebook-50-2.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}