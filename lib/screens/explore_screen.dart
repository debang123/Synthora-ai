import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy community creations
    final List<Map<String, dynamic>> communityCreations = [
      {'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80', 'score': 98, 'author': 'harsh_ai'},
      {'url': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=400&q=80', 'score': 95, 'author': 'syn_master'},
      {'url': 'https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?auto=format&fit=crop&w=400&q=80', 'score': 91, 'author': 'pixel_god'},
      {'url': 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80', 'score': 99, 'author': 'dream_weaver'},
      {'url': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=400&q=80', 'score': 88, 'author': 'cyber_punk'},
      {'url': 'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?auto=format&fit=crop&w=400&q=80', 'score': 96, 'author': 'neo_artist'},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0),
              child: Text(
                "Community Masterpieces",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Discover the highest CLIP scored syntheses",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search creations, users, tags...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    icon: const Icon(Icons.search, color: AppTheme.textMuted),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list, color: AppTheme.secondary),
                      onPressed: () {},
                    )
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: communityCreations.length,
                itemBuilder: (context, index) {
                  final item = communityCreations[index];
                  return _buildCommunityCard(item['url'], item['score'], item['author']);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(String url, int score, String author) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppTheme.background.withOpacity(0.95),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "@$author",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppTheme.secondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  "CLIP: $score%",
                  style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
