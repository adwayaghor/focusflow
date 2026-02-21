import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ===== Design Token Colors =====
  static const Color primary = Color(0xFFF47D5B);
  static const Color primaryHover = Color(0xFFE06A48);
  static const Color primaryLight = Color(0xFFFFF0EB);
  static const Color primaryUltraLight = Color(0xFFFFF7F3);

  static const Color secondary = Color(0xFFFFB880);
  static const Color secondaryLight = Color(0xFFFFF4E8);

  static const Color background = Color(0xFFFFFCF9);
  static const Color backgroundWarm = Color(0xFFFFF7F3);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  static const Color text = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFF7A7A7A);
  static const Color textMuted = Color(0xFFABABAB);

  static const Color border = Color(0xFFF0EDE9);
  static const Color borderLight = Color(0xFFF7F5F2);

  static const Color success = Color(0xFF6BCF7F);
  static const Color successBg = Color(0xFFEEFBF1);
  static const Color successDark = Color(0xFF4DB862);

  static const Color warning = Color(0xFFFFB880);
  static const Color warningBg = Color(0xFFFFF4E8);

  static const Color error = Color(0xFFFF6B6B);
  static const Color errorBg = Color(0xFFFFF0F0);

  // ===== Radius =====
  static const double radius = 16;
  static const double radiusSm = 10;
  static const double radiusXs = 6;
  static const double radiusFull = 999;

  // ===== Light Theme =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    primaryColor: primary,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      background: background,
      onBackground: text,
      surface: backgroundCard,
      onSurface: text,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: backgroundCard,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundWarm,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),

    dividerColor: border,

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: textLight,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textMuted,
        fontSize: 12,
      ),
      titleLarge: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}