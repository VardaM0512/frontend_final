// lib/app/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color seed = Color(0xFFFF6A00); // orange

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: const Color(0xFFE6E6E6),
      textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 15)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
