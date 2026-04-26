import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/clarity_api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ClarityApiService _apiService = ClarityApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final history = await _apiService.fetchUserHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () {
                      // Handled by navigation if pushed, but here it's part of main layout
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Your Creations",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                  : _history.isEmpty 
                    ? const Center(
                        child: Text(
                          "No creations yet.",
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _history.length > 0 ? _history.length : 4, // Show mock data if empty and we want to test UI
                        itemBuilder: (context, index) {
                          // Extremely strict, foolproof typing for Flutter Web
                          final dynamic rawItem = _history.isNotEmpty && index < _history.length ? _history[index] : null;
                          final bool isMap = rawItem != null && rawItem is Map;
                          
                          final String enhancedUrl = (isMap && rawItem['enhanced_url'] != null) ? rawItem['enhanced_url'].toString() : '';
                          final String imageUrl = enhancedUrl.isNotEmpty 
                              ? '${ClarityApiService.baseUrl}$enhancedUrl' 
                              : 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=${80 + index}';
                          
                          final String title = (isMap && rawItem['original_name'] != null) 
                              ? rawItem['original_name'].toString() 
                              : 'AI Masterpiece ${index + 1}';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title.length > 15 ? '${title.substring(0, 15)}...' : title,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Enhanced scene",
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
}
