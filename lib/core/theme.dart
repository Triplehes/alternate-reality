import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF09090B),
      surface = Color(0xFF141417),
      accent = Color(0xFFFF7058),
      muted = Color(0xFF9A979D);
}

ThemeData buildTheme() => ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'Helvetica Neue',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 50,
      fontWeight: FontWeight.w300,
      height: 1.03,
      letterSpacing: -2,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      letterSpacing: -1,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5),
  ),
  inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);
