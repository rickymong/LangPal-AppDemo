import 'package:flutter/material.dart';

class SocialLogoButtons extends StatelessWidget {
  const SocialLogoButtons({
    super.key,
  });

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
          onTap: () {
            print("Gmail");
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