import 'package:flutter/material.dart';
import '../utils/theme.dart';

import 'package:image_picker/image_picker.dart';
import '../services/clarity_api_service.dart';

class ProcessingScreen extends StatefulWidget {
  final List<XFile> imageFiles;
  final double fidelityWeight;

  const ProcessingScreen({
    super.key,
    required this.imageFiles,
    this.fidelityWeight = 0.5,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ClarityApiService _apiService = ClarityApiService();
  int _currentStepIndex = 0;
  Map<String, dynamic>? _resultData;

  List<String> get _steps {
    if (widget.imageFiles.length >= 2) {
      return [
        "Analyzing ${widget.imageFiles.length} photos for best features...",
        "Aligning facial landmarks across frames...",
        "Synthesizing high-fidelity composite...",
        "Applying neural beautification...",
      ];
    }
    return [
      "Detecting objects with YOLO...",
      "Segmenting features with DeepLab...",
      "Scoring quality with AI CLIP...",
      "Compositing final masterpiece..."
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Simulate initial steps for UX while API runs
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _currentStepIndex = 1);
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _currentStepIndex = 2);
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _currentStepIndex = 3);
    });

    // Use synthesis endpoint for 2+ images, enhance for single
    Map<String, dynamic>? data;
    if (widget.imageFiles.length >= 2) {
      data = await _apiService.synthesizeFeatures(
        widget.imageFiles,
        fidelityWeight: widget.fidelityWeight,
      );
    } else {
      data = await _apiService.enhanceImages(
        widget.imageFiles,
        fidelityWeight: widget.fidelityWeight,
      );
    }

    if (mounted) {
      setState(() {
        _resultData = data;
        _currentStepIndex = 4; // Done
      });
      
      // Delay slightly then go back with the result
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
         Navigator.pop(context, _resultData);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSynthesis = widget.imageFiles.length >= 2;
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF2E0947),
                  AppTheme.background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSynthesis ? "AI Fusion..." : "Processing...",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isSynthesis) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Extracting best features from ${widget.imageFiles.length} images",
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 48),

                  // Checklist Items
                  for (int i = 0; i < _steps.length; i++) ...[
                    Opacity(
                      opacity: _currentStepIndex >= i ? 1.0 : 0.5,
                      child: _buildChecklistItem(
                        _steps[i], 
                        _currentStepIndex > i, 
                        isPending: _currentStepIndex < i
                      ),
                    ),
                    if (i < _steps.length - 1) const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 64),

                  // Glowing processing circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animationController.value * 2 * 3.14159,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    isSynthesis ? Colors.amber : AppTheme.secondary,
                                    AppTheme.primary,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.background,
                        ),
                        child: Center(
                          child: Icon(
                            isSynthesis ? Icons.merge_type : Icons.auto_awesome, 
                            size: 60, 
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),

                  // Bottom Button (Disabled until done)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.surface.withOpacity(0.5),
                    ),
                    child: ElevatedButton(
                      onPressed: null, // Disabled
                      child: const Text("Select Images"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isCompleted, {bool isPending = false}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: isCompleted ? AppTheme.secondary : (isPending ? Colors.transparent : AppTheme.primary),
               border: Border.all(color: AppTheme.secondary),
             ),
             padding: const EdgeInsets.all(4),
             child: isCompleted 
                 ? const Icon(Icons.check, size: 16, color: AppTheme.background) 
                 : (isPending 
                     ? const SizedBox(width: 16, height: 16) 
                     : const SizedBox(
                         width: 16, 
                         height: 16, 
                         child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                       )),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}
