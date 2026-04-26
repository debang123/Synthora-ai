import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import 'account_settings_screen.dart';

import 'razorpay_checkout_screen.dart';
import '../services/clarity_api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ClarityApiService _apiService = ClarityApiService();
  int _credits = 50;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCredits();
  }

  Future<void> _fetchCredits() async {
    final credits = await _apiService.fetchUserCredits();
    if (mounted) {
      setState(() {
        _credits = credits;
        _isLoading = false;
      });
    }
  }

  void _launchUpgrade() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RazorpayCheckoutScreen()),
    );
    // If they bought credits, refresh!
    if (result == true) {
      _fetchCredits();
    }
  }

  void _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Derive name from display name or email
    String displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Explorer'; // Fallback to email prefix or Explorer
    String displayEmail = user?.email ?? 'user@example.com';
    
    // In real scenario we might fetch this from Firestore, but for now we format the display name
    if (user?.displayName == null && user?.email != null) {
      displayName = user!.email!.split('@')[0];
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Profile",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Avatar with Glow
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surface,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayEmail,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard("Creations", "24")),
                const SizedBox(width: 16),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                    : _buildStatCard("Credits", _credits.toString()),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pro Membership Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.8), AppTheme.secondary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Synthora Pro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text("Unlock unlimited 4K synthesis", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _launchUpgrade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10)
                        ]
                      ),
                      child: const Text("Upgrade", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings Items
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("App Settings", style: TextStyle(color: AppTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              Icons.image_outlined, 
              "Saved Images",
              onTap: () {
                if (widget.onNavigate != null) widget.onNavigate!(3); // Navigate to History Tab
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              Icons.settings_outlined, 
              "Account Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.dark_mode_outlined, "Dark Mode", isToggle: true, toggleValue: true),
            const SizedBox(height: 32),
            
            // Log out button
            GestureDetector(
              onTap: () => _handleLogout(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.logout, color: Colors.redAccent, size: 20),
                     SizedBox(width: 8),
                     Text(
                      "Log Out",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.white, bool isToggle = false, bool toggleValue = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontSize: 16),
              ),
            ),
            if (isToggle)
              Switch(
                value: toggleValue,
                onChanged: (val) {},
                activeColor: AppTheme.secondary,
              )
            else
              Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
