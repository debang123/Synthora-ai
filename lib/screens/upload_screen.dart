import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../services/clarity_api_service.dart';
import 'processing_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  final ClarityApiService _apiService = ClarityApiService();
  
  List<XFile> _selectedImages = [];
  Map<String, dynamic>? _resultData;
  bool _isProcessing = false;
  double _fidelityWeight = 0.5;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _apiService.pickImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
        _resultData = null;
      });
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedImages.isEmpty) return;

    final resultData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          imageFiles: _selectedImages,
          fidelityWeight: _fidelityWeight,
        ),
      ),
    );

    if (mounted) {
      if (resultData != null && resultData is Map<String, dynamic>) {
        setState(() {
          _resultData = resultData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enhancement failed. Please ensure the backend is running.')),
        );
      }
    }
  }

  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      return Image.network(file.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(file.path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Face Enhancement",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Transform your photos with AI magic",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            if (_resultData != null) ...[
              // Result State: Masterpiece + Diagnostics
              Text("Final Masterpiece", style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(_resultData!['enhanced_url'], fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 32),
              
              Text("Diagnostics & CLIP Scores", style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_resultData!['extracted_features'] != null)
                ...(_resultData!['extracted_features'] as List).map((feature) {
                   return Container(
                     margin: const EdgeInsets.only(bottom: 12),
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: AppTheme.surface,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(feature['feature'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                               const SizedBox(height: 4),
                               Text("Source: ${feature['original_name']}", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                             ],
                           ),
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: AppTheme.secondary.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Text(
                             "CLIP: ${(feature['clip_score'] * 100).toInt()}%",
                             style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                           ),
                         ),
                       ],
                     ),
                   );
                }),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: "Synthesize More",
                  onPressed: () {
                    setState(() {
                      _selectedImages = [];
                      _resultData = null;
                    });
                  },
                ),
              ),
            ] else ...[
               // Upload Initial State
               GestureDetector(
                 onTap: _pickImages,
                 child: Container(
                   width: double.infinity,
                   height: 320,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(32),
                     gradient: LinearGradient(
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                       colors: [
                          AppTheme.primary.withOpacity(0.15),
                          AppTheme.surface,
                       ],
                     ),
                     border: Border.all(color: AppTheme.secondary.withOpacity(0.2), width: 2),
                     boxShadow: [
                       BoxShadow(
                         color: AppTheme.primary.withOpacity(0.05),
                         blurRadius: 30,
                       ),
                     ],
                   ),
                   child: _selectedImages.isEmpty 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withOpacity(0.1),
                            ),
                            child: Icon(Icons.auto_awesome, size: 64, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 24),
                          Text("Tap to select photos", style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text("Select up to 10 images.", style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AspectRatio(
                                aspectRatio: 3/4,
                                child: _buildImagePreview(_selectedImages[index]),
                              ),
                            ),
                          );
                        },
                      ),
                 ),
               ),
               
               if (_selectedImages.isNotEmpty) ...[
                 const SizedBox(height: 32),
                 GlassContainer(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text("Enhancement Strength", style: TextStyle(color: AppTheme.textMain)),
                           Text("${(_fidelityWeight * 100).toInt()}%", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                         ],
                       ),
                       Slider(
                         value: _fidelityWeight,
                         min: 0.1,
                         max: 1.0,
                         activeColor: AppTheme.primary,
                         inactiveColor: AppTheme.surface,
                         onChanged: (val) {
                           setState(() {
                             _fidelityWeight = val;
                           });
                         },
                       ),
                       const Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text("More AI", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                           Text("Original", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                         ],
                       ),
                     ],
                   )
                 ),
                 const SizedBox(height: 32),
                 SizedBox(
                   width: double.infinity,
                   child: CustomButton(
                     label: "Enhance Now ✨",
                     onPressed: _startProcessing,
                   ),
                 ),
               ]
            ],
          ],
        ),
      ),
    );
  }
}
