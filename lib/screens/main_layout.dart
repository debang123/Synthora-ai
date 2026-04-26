import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';
import 'explore_screen.dart';
import 'history_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    DashboardScreen(
      onNavigate: (index) => setState(() => _currentIndex = index),
    ),
    const ExploreScreen(),
    const UploadScreen(),
    const HistoryScreen(),
    ProfileScreen(
      onNavigate: (index) => setState(() => _currentIndex = index),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fluid_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Page Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0), // Reserve space for nav bar
                child: _pages[_currentIndex],
              ),
            ),
          ),
          
          // Floating Pill Navigation Bar
          Positioned(
            bottom: 24, // Float above the screen bottom
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Pill Background
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(Icons.home_filled, "Home", 0),
                            _buildNavItem(Icons.explore_outlined, "Explore", 1),
                            const SizedBox(width: 56), // Space for center action
                            _buildNavItem(Icons.history_outlined, "History", 3),
                            _buildNavItem(Icons.person_outline, "Profile", 4),
                          ],
                        ),
                      ),
                      // Center Action Item (breaking out)
                      Positioned(
                        top: -15, // Break out of the pill
                        child: _buildCenterActionItem(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      extendBody: true,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionItem() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
