import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32), // A nice dark green
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
);