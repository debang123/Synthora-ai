import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../services/clarity_api_service.dart';

class RazorpayCheckoutScreen extends StatefulWidget {
  const RazorpayCheckoutScreen({super.key});

  @override
  State<RazorpayCheckoutScreen> createState() => _RazorpayCheckoutScreenState();
}

class _RazorpayCheckoutScreenState extends State<RazorpayCheckoutScreen> {
  bool _isProcessing = false;
  final ClarityApiService _apiService = ClarityApiService();

  Future<void> _launchUPI() async {
    // Exact UPI ID requested by user
    final Uri upiUrl = Uri.parse("upi://pay?pa=9636811249@nyes&pn=SynthoraAI&am=99.00&cu=INR");
    
    try {
      // Ignore canLaunchUrl on web because it always returns false for 'upi://'
      await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Could not launch UPI URL: \$e");
    }
    
    // Always simulate verification after click so the user can test the flow!
    _simulatePaymentVerification();
  }

  Future<void> _simulatePaymentVerification() async {
    setState(() => _isProcessing = true);
    
    // Simulate network delay for verification
    await Future.delayed(const Duration(seconds: 3));
    
    // Call backend to securely verify and add 100 credits
    final newBalance = await _apiService.verifyPayment();
    
    if (mounted) {
      setState(() => _isProcessing = false);
      if (newBalance != null) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment verification failed. Contact support.")),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("Payment Successful!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "100 Credits have been added to your account. You can now generate more AI images!",
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(true); // close checkout screen and return true
            },
            child: const Text("Awesome!", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B), // Razorpay dark theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 24),
                Text("Verifying Payment...", style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 8),
                Text("Please do not close this window.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          )
        : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Razorpay Header Mockup
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blueAccent, size: 28),
                SizedBox(width: 8),
                Text("Razorpay", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Spacer(),
                Text("Test Mode", style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 48),
            
            // Order Summary
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text("Synthora Pro Upgrade", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text("100 AI Generation Credits", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 24),
                  const Text("₹99.00", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Spacer(),
            
            // Payment Methods
            const Text("PAY WITH", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            
            // UPI Button
            GestureDetector(
              onTap: _launchUPI,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white),
                    SizedBox(width: 16),
                    Text("UPI (GPay, PhonePe, Paytm)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Card Mockup
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Test Mode: Card payments disabled. Please use UPI to test.")),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.white54),
                    SizedBox(width: 16),
                    Text("Card (Visa, MasterCard)", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Footer
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.white38, size: 12),
                  SizedBox(width: 4),
                  Text("Secured by Razorpay", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
