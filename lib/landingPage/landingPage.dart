import 'package:flutter/material.dart';
import 'package:langpal_prototype/userAuth/accountSetup.dart/firstLangSelect.dart';
import '../userAuth/login/loginPage.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  static const Color _teal = Color.fromARGB(255, 48, 186, 202);
  static const Color _deepTeal = Color.fromARGB(255, 7, 172, 190);
  static const Color _aqua = Color(0xFFE7FBFD);
  static const List<_FeatureItem> _features = [
    _FeatureItem(
      icon: Icons.record_voice_over_rounded,
      title: 'AI Tutors',
      subtitle: 'Practice with realistic AI characters',
      accentColor: _deepTeal,
      backgroundColor: Color(0xFFE4F8FB),
    ),
    _FeatureItem(
      icon: Icons.extension_rounded,
      title: 'Fun Games',
      subtitle: 'Build vocabulary through quick challenges',
      accentColor: Color(0xFFFF9600),
      backgroundColor: Color(0xFFFFF3E2),
    ),
    _FeatureItem(
      icon: Icons.trending_up_rounded,
      title: 'Track Progress',
      subtitle: 'See your learning streak grow daily',
      accentColor: Color(0xFF58CC02),
      backgroundColor: Color(0xFFEAF9E4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _aqua,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD8F9FC),
                Color(0xFFECFDFF),
                Colors.white,
              ],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isShortScreen = constraints.maxHeight < 700;
              final horizontalPadding = screenWidth < 360 ? 18.0 : 24.0;
              final availableHeight = constraints.maxHeight;
              final mascotHeight =
                  (availableHeight * (isShortScreen ? 0.2 : 0.3))
                      .clamp(isShortScreen ? 132.0 : 170.0, 270.0);
              final titleSize = (screenWidth * 0.115).clamp(38.0, 54.0);
              final subtitleSize = (screenWidth * 0.04).clamp(14.0, 17.0);

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isShortScreen ? 12 : 20,
                    horizontalPadding,
                    20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnimatedMascot(mascotHeight),
                        SizedBox(height: isShortScreen ? 8 : 12),
                        Text(
                          'LangPal',
                          style: TextStyle(
                            fontSize: titleSize,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF102B2F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Learn languages naturally through AI conversations',
                          style: TextStyle(
                            fontSize: subtitleSize,
                            height: 1.35,
                            color: const Color(0xFF49666A),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isShortScreen ? 22 : 32),
                        _buildFeatureCards(isShortScreen),
                        SizedBox(height: isShortScreen ? 24 : 34),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FirstLangSelectPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 8,
                            shadowColor: _deepTeal.withValues(alpha: 0.28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmailEntryPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF18484E),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('I already have an account'),
                        ),
                        SizedBox(height: isShortScreen ? 8 : 14),
                        const Text(
                          'Free to start | Premium features available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D7C80),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMascot(double mascotHeight) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/langpal_logos/LangPal-Primary-mascot.png',
        height: mascotHeight,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildFeatureCards(bool isShortScreen) {
    return Column(
      children: [
        for (int i = 0; i < _features.length; i++) ...[
          _FeatureCard(
            feature: _features[i],
            isCompact: isShortScreen,
          ),
          if (i != _features.length - 1)
            SizedBox(height: isShortScreen ? 10 : 12),
        ],
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.isCompact,
  });

  final _FeatureItem feature;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 46.0 : 52.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F8B99).withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: feature.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              feature.icon,
              color: feature.accentColor,
              size: isCompact ? 24 : 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172F33),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xFF607276),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
