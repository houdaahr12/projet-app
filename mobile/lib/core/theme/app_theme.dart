import 'package:flutter/material.dart';

import 'package:mobile/core/theme/colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: SepsisColors.teal,
        primary: SepsisColors.teal,
        surface: SepsisColors.surface,
      ),
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const buttonText = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    OutlineInputBorder input(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );

    return base.copyWith(
      scaffoldBackgroundColor: SepsisColors.canvas,
      textTheme: base.textTheme.apply(
        bodyColor: SepsisColors.navy,
        displayColor: SepsisColors.navy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SepsisColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SepsisColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: SepsisColors.navy,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: rounded, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: rounded,
          textStyle: buttonText,
          side: const BorderSide(color: SepsisColors.border),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: SepsisColors.surface,
        border: input(SepsisColors.border),
        enabledBorder: input(SepsisColors.border),
        focusedBorder: input(SepsisColors.teal),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SepsisColors.navy,
        shape: rounded,
      ),
    );
  }
}
