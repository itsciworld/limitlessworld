import 'package:flutter/material.dart';

/// Application color palette matching the cosmic/space theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF0A7AFF);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color accentBlue = Color(0xFF00D9FF);

  // Background Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF0A0E1A);
  static const Color inputBackground = Color(0xFF0D1425);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E9AB8);
  static const Color textHint = Color(0xFF4A5568);

  // Border Colors
  static const Color borderColor = Color(0xFF1E3A5F);
  static const Color borderActive = Color(0xFF0A7AFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A7AFF), Color(0xFF0052CC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [
      Color(0xFF0A1128),
      Color(0xFF001F54),
      Color(0xFF034078),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Social Media Colors
  static const Color googleRed = Color(0xFFDB4437);
  static const Color appleWhite = Color(0xFFFFFFFF);
}
