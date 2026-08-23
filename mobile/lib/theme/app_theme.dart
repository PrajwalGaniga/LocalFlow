import 'package:flutter/material.dart';

class AppTheme {
  // Canvas & Surfaces
  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF3F3F2);
  static const Color surfaceMuted = Color(0xFFE8E8E7);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Typography Colors
  static const Color textPrimary = Color(0xFF272727);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Dark CTA
  static const Color ctaDark = Color(0xFF272727);

  // Provider Palette (Warm Coral / Orange)
  static const Color providerPrimary = Color(0xFFFF5A2A);
  static const Color providerCoral = Color(0xFFFF7651);
  static const Color providerPeach = Color(0xFFFFE0D0);
  static const Color providerDark = Color(0xFFD64417);

  // Consumer Palette (Fresh Emerald / Green + Coral Accent)
  static const Color consumerPrimary = Color(0xFF059669);
  static const Color consumerMint = Color(0xFF10B981);
  static const Color consumerSoft = Color(0xFFD1FAE5);
  static const Color consumerAccentCoral = Color(0xFFFF6A24);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Backward compatibility aliases
  static const Color primary = providerPrimary;
  static const Color primaryLight = providerCoral;
  static const Color accent = providerPeach;

  // Gradients
  static const LinearGradient providerHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5A2A), Color(0xFFFF7651), Color(0xFFF7B39A)],
  );

  static const LinearGradient consumerHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF6EE7B7)],
  );

  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
  );

  // Card & Button Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> heroShadow = [
    BoxShadow(
      color: const Color(0xFFFF5A2A).withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> consumerHeroShadow = [
    BoxShadow(
      color: const Color(0xFF059669).withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: providerPrimary,
      colorScheme: const ColorScheme.light(
        primary: providerPrimary,
        secondary: consumerPrimary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: Colors.black.withValues(alpha: 0.12), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: providerPrimary, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
      ),
    );
  }
}
