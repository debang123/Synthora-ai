import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "titlePart1": "AI-Powered\n",
      "titlePart2": "Image Fusion",
      "description": "Combine multiple images and let AI extract the best from each.",
      "image": "assets/images/onboarding_1.png"
    },
    {
      "titlePart1": "Extract the Best\n",
      "titlePart2": "from Every Image",
      "description": "Our AI analyzes sharpness, brightness, texture, and objects from your uploads.",
      "image": "assets/images/onboarding_2.png"
    },
    {
      "titlePart1": "Smart Analysis\n",
      "titlePart2": "Perfect Results",
      "description": "Advanced neural networks find the perfect features and create stunning new images.",
      "image": "assets/images/onboarding_3.png"
    },
    {
      "titlePart1": "Your Imagination,\n",
      "titlePart2": "Enhanced",
      "description": "From landscapes to portraits, objects to art—synthora AI brings out the best in every detail.",
      "image": "assets/images/onboarding_4.png"
    }
  ];

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _autoPlayTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Deep space gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF07051A), Color(0xFF100D30), Color(0xFF07051A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header (Skip Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _currentPage < 4 
                        ? TextButton(
                            onPressed: () {
                              _autoPlayTimer?.cancel();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Text("Skip", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          )
                        : const SizedBox(height: 48), // Spacer for page 5 to match layout
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      if (index < 4) {
                        _startAutoPlay(); // Restart timer on manual swipe/key press
                      } else {
                        _autoPlayTimer?.cancel();
                      }
                    },
                    itemCount: 5, // 4 info slides + 1 final slide
                    itemBuilder: (context, index) {
                      if (index == 4) return _buildFinalSlide();
                      return _buildInfoSlide(index);
                    },
                  ),
                ),
                
                // Bottom Indicators (Only for slides 1-4)
                if (_currentPage < 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: List.generate(
                            4,
                            (index) => buildDot(index, context),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          "${_currentPage + 1} / 5",
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSlide(int index) {
    final data = onboardingData[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom 3D Illustration
          Expanded(
            flex: 6,
            child: Center(
              child: Image.asset(
                data["image"],
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Two-Tone Title
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: data["titlePart1"],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: data["titlePart2"],
                        style: const TextStyle(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  data["description"],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Central Logo
          Center(
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondary.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/synthora_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Synthora AI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          
          // Tagline
          const Text.rich(
            TextSpan(
              text: "Create. Enhance.\n",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: "Inspire.",
                  style: TextStyle(
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Let AI turn your images into something\nextraordinary.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const Spacer(),
          
          // Bottom CTA
          CustomButton(
            label: "Let's Begin",
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icons.arrow_forward,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text.rich(
              TextSpan(
                text: "Already have an account? ",
                style: TextStyle(color: AppTheme.textMuted),
                children: [
                  TextSpan(
                    text: "Sign In",
                    style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 6,
      width: _currentPage == index ? 24 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.secondary : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
