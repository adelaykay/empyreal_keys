import 'package:flutter/material.dart';

class AppTheme {
  // Define the primary colors
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFFE76F6B);
  static const Color scaffoldBackgroundColor = Color(0xFFECF4FC);
  static const Color accentColor = Color(0xFFFFC107);

  // Define the text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );

  // Define shadows
  static const List<Shadow> textShadows = [
    Shadow(
      offset: Offset(1.0, 1.0),
      blurRadius: 2.0,
      color: Colors.grey,
    ),
  ];

  // Define the light theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(
      headlineLarge: headingStyle,
      bodyLarge: bodyTextStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: headingStyle.copyWith(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryColor,  // Primary or highlight color for active items
      unselectedItemColor: Color(0xFF9949BA5), // Muted or on-surface color for inactive items
    ),
  );

  // Define the dark theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(
      headlineLarge: headingStyle,
      bodyLarge: bodyTextStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: headingStyle.copyWith(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white, // Text/icon color
      sizeConstraints: BoxConstraints.tightFor(
        width: 70.0,
        height: 70.0,
      ),
    ),
  );
}
