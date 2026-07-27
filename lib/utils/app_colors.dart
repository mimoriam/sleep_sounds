import 'package:flutter/material.dart';

class AppColors {
  // Core Backgrounds (Dark)
  static const Color backgroundDark = Color(0xFF0B101E); // Deep navy background
  static const Color cardColor = Color(0xFF151C2C); // Slightly lighter navy for cards, text fields, and bottom nav

  // Core Backgrounds (Light)
  static const Color backgroundLight = Color(0xFFF5F7FA); // Light grayish background
  static const Color cardColorLight = Color(0xFFFFFFFF); // Pure white for cards

  // Primary & Accent Colors
  static const Color primaryCyan = Color(0xFF26C6DA); // Used for active text, icons, and sliders
  static const Color primaryBlue = Color(0xFF29B6F6); // Mid-tone blue for gradients
  static const Color primaryPurple = Color(0xFF7E57C2); // Purple tone for gradients
  static const Color errorRed = Color(0xFFFF4C4C); // Used for error states

  // Text Colors (Dark Theme)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for headings
  static const Color textSecondary = Color(0xFF8F9BB3); // Muted blue-gray for subtitles

  // Text Colors (Light Theme)
  static const Color textPrimaryLight = Color(0xFF111827); // Dark charcoal for headings
  static const Color textSecondaryLight = Color(0xFF6B7280); // Muted dark gray for subtitles
  static const Color textDark = Color(0xFF0B101E);

  // Borders and Dividers
  static const Color borderLight = Color(0xFF2A3547); // Subtle dark theme border
  static const Color borderLightMode = Color(0xFFE5E7EB); // Subtle light theme border

  // Context-aware color helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color card(BuildContext context) =>
      isDark(context) ? cardColor : cardColorLight;

  static Color text(BuildContext context) =>
      isDark(context) ? textPrimary : textPrimaryLight;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? textSecondary : textSecondaryLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderLight : borderLightMode;

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
