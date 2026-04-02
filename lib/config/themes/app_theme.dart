import 'package:flutter/material.dart';

class AppTheme {
  // Цветовая схема: Чёрный + Зелёный акцент
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF121212);
  static const Color lightGrey = Color(0xFF2C2C2C);
  static const Color greenAccent = Color(0xFF4CAF50);
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    
    colorScheme: const ColorScheme.dark(
      primary: greenAccent,
      secondary: greenAccent,
      surface: darkGrey,
      background: black,
      error: Color(0xFFCF6679),
      onPrimary: black,
      onSecondary: black,
      onSurface: white,
      onBackground: white,
    ),
    
    primaryColor: greenAccent,
    scaffoldBackgroundColor: black,
    cardColor: darkGrey,
    dividerColor: white54,
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: white, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: white, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: white),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: white),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: white),
      bodyLarge: TextStyle(fontSize: 16, color: white, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: white70, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: white),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: greenAccent,
        foregroundColor: black,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: white,
        side: const BorderSide(color: white70, width: 1),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: greenAccent,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: greenAccent, width: 2),  // ✅ Зелёный
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFCF6679), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFCF6679), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: white70),
      hintStyle: TextStyle(color: white54),
      prefixIconColor: white70,
      suffixIconColor: white70,
    ),
    
    cardTheme: const CardThemeData(
      color: darkGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      margin: EdgeInsets.zero,
    ),
    
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: white70,
        fontSize: 16,
      ),
    ),
    
    chipTheme: const ChipThemeData(
      backgroundColor: lightGrey,
      disabledColor: Color(0xFF2C2C2C),
      selectedColor: greenAccent,
      secondarySelectedColor: greenAccent,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: white),
      secondaryLabelStyle: TextStyle(color: black),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return greenAccent;
        }
        return white70;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return greenAccent.withOpacity(0.5);
        }
        return white54;
      }),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: greenAccent,
      linearTrackColor: lightGrey,
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: greenAccent,
      unselectedLabelColor: white70,
      indicatorColor: greenAccent,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}