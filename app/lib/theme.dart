import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32), // Dark Green
    primary: const Color(0xFF2E7D32),
    secondary: const Color(0xFF4CAF50),
    surface: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    color: Colors.white,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade100,
    thickness: 1,
    space: 1,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 2,
    backgroundColor: Color(0xFF2E7D32),
    foregroundColor: Colors.white,
    shape: StadiumBorder(),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFF2E7D32).withAlpha(25),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32));
      }
      return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFF2E7D32));
      }
      return const IconThemeData(color: Colors.black54);
    }),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1.0, color: Colors.black87),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5, color: Colors.black87),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);