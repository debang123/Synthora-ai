import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';

import '../services/clarity_api_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ClarityApiService _apiService = ClarityApiService();
  List<dynamic> _recentCreations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecent();
  }

  Future<void> _fetchRecent() async {
    final history = await _apiService.fetchUserHistory();
    if (mounted) {
      setState(() {
        _recentCreations = history.take(3).toList(); // Show only top 3 recent
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${AuthService().currentUser?.displayName?.split(' ').first ?? AuthService().currentUser?.email?.split('@').first ?? 'Explorer'}",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Welcome to Synthora AI",
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatBadge(Icons.auto_awesome, "Credits", "1,250", AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatBadge(Icons.image_outlined, "Syntheses", "24", AppTheme.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Upload Images Card
              GestureDetector(
                onTap: () {
                  if (widget.onNavigate != null) widget.onNavigate!(2); // Navigate to Upload Screen
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withOpacity(0.15),
                        AppTheme.secondary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: AppTheme.secondary.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Upload Images",
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Start Anti-Hallucination Pipeline",
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Quick Actions
              const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickAction("Enhance Face", Icons.face, AppTheme.primary),
                    _buildQuickAction("Upscale 4K", Icons.high_quality, AppTheme.secondary),
                    _buildQuickAction("Remove BG", Icons.layers_clear, Colors.purpleAccent),
                    _buildQuickAction("Colorize", Icons.color_lens, Colors.orangeAccent),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recent Creations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Creations",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.onNavigate != null) widget.onNavigate!(3); // Navigate to History
                    },
                    child: const Text("See All", style: TextStyle(color: AppTheme.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal List of Creations
              _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : SizedBox(
                    height: 180, // Height matching mockup
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentCreations.isNotEmpty ? _recentCreations.length : 3,
                      itemBuilder: (context, index) {
                        // Safe extraction logic
                        final dynamic rawItem = _recentCreations.isNotEmpty && index < _recentCreations.length ? _recentCreations[index] : null;
                        final bool isMap = rawItem != null && rawItem is Map;
                        
                        final String enhancedUrl = (isMap && rawItem['enhanced_url'] != null) ? rawItem['enhanced_url'].toString() : '';
                        
                        final ImageProvider imageProvider = enhancedUrl.isNotEmpty
                            ? NetworkImage('${ClarityApiService.baseUrl}$enhancedUrl') as ImageProvider
                            : AssetImage('assets/images/onboarding_${index + 1}.png');

                        final String title = (isMap && rawItem['original_name'] != null) 
                            ? rawItem['original_name'].toString() 
                            : 'Creation ${index + 1}';

                        return Container(
                          width: 150, // Wider for premium feel
                          margin: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.background.withOpacity(0.9),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.length > 12 ? '${title.substring(0, 12)}...' : title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Enhanced scene",
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) widget.onNavigate!(2); // Default all quick actions to Upload Screen for now
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
