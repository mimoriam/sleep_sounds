import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding.dart';
import 'utils/app_themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Sounds',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme for sleep aesthetics
      home: const OnboardingScreen(),
    );
  }
}

