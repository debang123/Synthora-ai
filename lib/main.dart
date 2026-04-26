import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_layout.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const SynthoraApp());
}

class SynthoraApp extends StatelessWidget {
  const SynthoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synthora AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // Temporary basic routing since GoRouter needs actual dependency resolution which fails
      // when Flutter SDK is missing on the host to do a `pub get`
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}
