import 'package:flutter/material.dart';

/// Obsidian Glassmorphism Design System (Executive Dark Mode)
/// Tailored for 120 FPS high-contrast, ultra-luxurious mobile & web experience.
class AppTheme {
  // Core Obsidian Palette
  static const Color obsidianNavy = Color(0xFF06090E);
  static const Color cardSurface = Color(0xDE0E1420); // #0E1420 with ~0.87 opacity
  static const Color cardSurfaceRaw = Color(0xFF0E1420);
  static const Color borderNeonSubtle = Color(0xFF1E293B);
  static const Color borderGlowCyan = Color(0x3300F2FE);

  // Accents
  static const Color electricCyan = Color(0xFF00F2FE);
  static const Color mintEmerald = Color(0xFF10B981);
  static const Color royalIndigo = Color(0xFF6366F1);
  static const Color amberGold = Color(0xFFF59E0B);
  static const Color sunsetCoral = Color(0xFFEF4444);
  static const Color purpleNeon = Color(0xFF8B5CF6);

  // Typography Colors
  static const Color cleanAlabaster = Color(0xFFF8FAFC);
  static const Color subduedSilver = Color(0xFF94A3B8);
  static const Color mutedSlate = Color(0xFF64748B);

  // Card Glassmorphic Decoration
  static BoxDecoration glassCard({
    BorderRadiusGeometry? borderRadius,
    Color? borderColor,
    double borderWidth = 1.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: cardSurface,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? borderNeonSubtle,
        width: borderWidth,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: electricCyan.withOpacity(0.03),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          ],
    );
  }

  // Micro-capsule Badge Decoration
  static BoxDecoration microCapsuleBadge({
    required Color accentColor,
    double opacity = 0.15,
  }) {
    return BoxDecoration(
      color: accentColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accentColor.withOpacity(0.40),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.18),
          blurRadius: 10,
          spreadRadius: -1,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianNavy,
      canvasColor: obsidianNavy,
      primaryColor: electricCyan,
      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: mintEmerald,
        tertiary: royalIndigo,
        surface: cardSurfaceRaw,
        error: sunsetCoral,
        onPrimary: obsidianNavy,
        onSecondary: Colors.white,
        onSurface: cleanAlabaster,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: cleanAlabaster,
          letterSpacing: -0.8,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: cleanAlabaster,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cleanAlabaster,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cleanAlabaster,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: subduedSilver,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: subduedSilver,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: mutedSlate,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: obsidianNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: cleanAlabaster),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cleanAlabaster,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderNeonSubtle,
        thickness: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderGlowCyan),
        ),
        textStyle: const TextStyle(color: cleanAlabaster, fontSize: 12),
      ),
    );
  }
}
