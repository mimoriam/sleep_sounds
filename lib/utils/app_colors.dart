import 'package:flutter/material.dart';

class AppColors {
  // Core Backgrounds
  static const Color backgroundDark = Color(0xFF0B101E); // Deep navy background
  static const Color cardColor = Color(
    0xFF151C2C,
  ); // Slightly lighter navy for cards, text fields, and bottom nav

  // Primary & Accent Colors
  static const Color primaryCyan = Color(
    0xFF26C6DA,
  ); // Used for active text, icons, and sliders
  static const Color primaryBlue = Color(
    0xFF29B6F6,
  ); // Mid-tone blue for gradients
  static const Color primaryPurple = Color(
    0xFF7E57C2,
  ); // Purple tone for gradients
  static const Color errorRed = Color(
    0xFFFF4C4C,
  ); // Used for logout and error states

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for headings
  static const Color textSecondary = Color(
    0xFF8F9BB3,
  ); // Muted blue-gray for subtitles and unselected items
  static const Color textDark = Color(
    0xFF0B101E,
  ); // Dark text for light theme compatibility

  // Borders and Dividers
  static const Color borderLight = Color(
    0xFF2A3547,
  ); // Subtle borders for cards and inputs

  // Gradients
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue, primaryCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient activeSliderGradient = LinearGradient(
    colors: [primaryCyan, primaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
