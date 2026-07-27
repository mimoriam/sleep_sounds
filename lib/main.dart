import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/audio_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/navbar/navbar.dart';
import 'screens/onboarding/onboarding.dart';
import 'services/audio_handler.dart';
import 'services/notification_service.dart';
import 'utils/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ScreenBrightness().resetScreenBrightness();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();

  SleepAudioHandler? audioHandler;
  try {
    audioHandler = await initAudioHandler() as SleepAudioHandler?;
  } catch (e) {
    debugPrint('AudioHandler init note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(audioHandler: audioHandler),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Sleep Sounds',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: settings.themeMode,
      home: settings.hasCompletedOnboarding
          ? const Navbar()
          : const OnboardingScreen(),
    );
  }
}
