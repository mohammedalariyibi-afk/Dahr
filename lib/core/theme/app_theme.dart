import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Explicit Material 3 scheme — cream / burgundy / gold only (no seed purple).
  static ColorScheme get _scheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.burgundy,
        onPrimary: AppColors.onBurgundy,
        primaryContainer: AppColors.burgundySoft,
        onPrimaryContainer: AppColors.onBurgundy,
        secondary: AppColors.gold,
        onSecondary: AppColors.onGold,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: AppColors.onGold,
        tertiary: AppColors.goldDark,
        onTertiary: AppColors.onGold,
        tertiaryContainer: AppColors.goldLight,
        onTertiaryContainer: AppColors.ink,
        error: AppColors.error,
        onError: AppColors.onBurgundy,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.creamDark,
        surfaceContainerLowest: AppColors.cream,
        surfaceContainerLow: AppColors.creamDark,
        surfaceContainer: AppColors.creamDark,
        surfaceContainerHigh: AppColors.creamDark,
        surfaceContainerHighest: AppColors.border,
        inverseSurface: AppColors.ink,
        onInverseSurface: AppColors.cream,
        inversePrimary: AppColors.gold,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  static ThemeData get light {
    final scheme = _scheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: AppColors.onBurgundy,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.burgundy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.burgundy,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.burgundy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.inkMuted),
        hintStyle: const TextStyle(color: AppColors.inkFaint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        selectedColor: AppColors.chipSelectedBg,
        labelStyle: const TextStyle(color: AppColors.chipFg),
        secondaryLabelStyle: const TextStyle(color: AppColors.chipSelectedFg),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.burgundy,
        unselectedItemColor: AppColors.inkFaint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: AppColors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.inkMuted),
        labelLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.burgundy,
      ),
    );
  }
}
