import 'package:flutter/material.dart';

// 1. Define your palette
class AppColors {
  // Primary: A warm, vibrant Peach-Orange
  static const primary = Color(0xFFFF8A65); // Deep Peach / Coral Orange
  
  // Secondary: A Dark Brownish-Grey (better contrast on peach than pure black)
  static const secondary = Color(0xFF4E342E); 
  
  // Backgrounds
  static const background = Color(0xFFFFF3E0); // Very Light Cream/Orange tint
  static const cardColor = Colors.white;
  
  // Status Colors (Adjusted to match warm tone)
  static const success = Color(0xFF66BB6A);    // Soft Green
  static const error = Color(0xFFEF5350);      // Soft Red
  static const disabled = Color(0xFFFFCCBC);   // Faded Peach for disabled items
  
  // Text on Primary
  static const onPrimary = Colors.white;
}

// 2. Define the Theme
final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  
  // Define Color Scheme (M3 requirement)
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    background: AppColors.background,
    surface: AppColors.cardColor,
    error: AppColors.error,
  ),

  // Typography
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: AppColors.secondary),
    bodyMedium: TextStyle(color: AppColors.secondary),
  ),
  
  // Card Design
  cardTheme: CardThemeData(
    color: AppColors.cardColor,
    elevation: 2, // Lighter elevation for cleaner look
    shadowColor: Colors.orange.withOpacity(0.2), // Warm shadow
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Input Fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    // Soft Orange Border
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    labelStyle: TextStyle(color: AppColors.secondary.withOpacity(0.7)),
    prefixIconColor: AppColors.primary,
  ),
  
  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 3,
      shadowColor: AppColors.primary.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),

  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.secondary,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.primary),
    titleTextStyle: TextStyle(
      color: AppColors.secondary, 
      fontSize: 20, 
      fontWeight: FontWeight.bold
    ),
  ),

  // Floating Action Button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),

  // Chip Theme (for Date Selectors)
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: AppColors.primary,
    secondarySelectedColor: AppColors.primary,
    labelStyle: const TextStyle(color: AppColors.secondary),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
    ),
  ),
);
