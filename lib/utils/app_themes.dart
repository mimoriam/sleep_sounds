import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  // --- SPACING & PADDING CONSTANTS ---
  static const double paddingScreen = 24.0;
  static const double paddingCard = 16.0;
  static const double borderRadiusButton = 30.0; // Pill-shaped buttons
  static const double borderRadiusCard = 20.0; // Soft rounded cards
  static const double borderRadiusInput = 16.0; // Text input fields

  // --- DARK THEME (Primary) ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryCyan,
      fontFamily: 'Inter', // Recommended sans-serif font for this design

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.primaryPurple,
        surface: AppColors.backgroundDark,
        error: AppColors.errorRed,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ), // Screen titles
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ), // Standard text
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ), // Subtitles
        labelSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Elevated Buttons (Gradient buttons handled separately via custom widgets, but base styling is here)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.transparent, // Transparent to allow Ink/Gradients
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(
            double.infinity,
            56,
          ), // Full-width standard button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),

      // Cards (Settings, Now Playing items)
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark, // Blends with background
        selectedItemColor: AppColors.primaryCyan,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // --- LIGHT THEME (Fallback/Secondary) ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Soft light background
      primaryColor: AppColors.primaryCyan,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryCyan,
        secondary: AppColors.primaryBlue,
        surface: Color(0xFFF5F7FA),
        error: AppColors.errorRed,
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textDark,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Standardize input, button, and card shapes to match dark theme structure
      inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      cardTheme: darkTheme.cardTheme.copyWith(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }
}
