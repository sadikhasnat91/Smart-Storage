import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42DB);

  // Accent
  static const Color accent = Color(0xFF00D9FF);
  static const Color accentLight = Color(0xFF66E8FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00E4C1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category colors
  static const Color images = Color(0xFFFF6B6B);
  static const Color videos = Color(0xFF4ECDC4);
  static const Color audio = Color(0xFFFFBE0B);
  static const Color documents = Color(0xFF6C63FF);
  static const Color apps = Color(0xFFFF6392);
  static const Color other = Color(0xFF845EC2);

  // Dark theme
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);

  // Light theme
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF00C9A7);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF00D9FF);
}
