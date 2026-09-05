import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ColorScheme get _scheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.glacier,
        onPrimary: AppColors.onBurgundy,
        primaryContainer: AppColors.burgundySoft,
        onPrimaryContainer: AppColors.glacier,
        secondary: AppColors.gold,
        onSecondary: AppColors.onGold,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: AppColors.onGold,
        tertiary: AppColors.burgundyDark,
        onTertiary: AppColors.ink,
        tertiaryContainer: AppColors.burgundySoft,
        onTertiaryContainer: AppColors.glacier,
        error: AppColors.error,
        onError: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.creamDark,
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: AppColors.surface,
        surfaceContainer: AppColors.creamDark,
        surfaceContainerHigh: AppColors.creamDark,
        surfaceContainerHighest: AppColors.skeletonHighlight,
        inverseSurface: AppColors.ink,
        onInverseSurface: AppColors.background,
        inversePrimary: AppColors.glacier,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  static ThemeData forLocale(Locale locale) {
    final scheme = _scheme;
    final isAr = locale.languageCode == 'ar';
    final darkBase = ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        );
    // Arabic keeps Flutter's bundled fallbacks so glyphs render before webfonts load.
    var textTheme = isAr
        ? darkBase
        : GoogleFonts.plusJakartaSansTextTheme(darkBase);

    if (!isAr) {
      textTheme = textTheme.copyWith(
        displayLarge: GoogleFonts.libreCaslonText(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 42,
          height: 52 / 42,
        ),
        displayMedium: GoogleFonts.libreCaslonText(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.libreCaslonText(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          height: 32 / 24,
        ),
        headlineSmall: GoogleFonts.libreCaslonText(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.glacier,
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
          foregroundColor: AppColors.glacier,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.glacier, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.glacier,
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
          borderSide: const BorderSide(color: AppColors.glacier, width: 1.5),
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.glacier.withOpacity(0.18),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.glacier : AppColors.inkFaint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.glacier : AppColors.inkFaint,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.glacier,
        foregroundColor: AppColors.onBurgundy,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.glacier,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
