import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Explicit Material 3 scheme — Ice Blue glass on Slate 950 (no seed purple).
  static ColorScheme get _scheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.iceBlue,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.iceBlueGlow,
        onPrimaryContainer: AppColors.iceBlue,
        secondary: AppColors.iceBlue,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.iceBlueHover,
        onSecondaryContainer: AppColors.iceBlue,
        tertiary: AppColors.textSecondary,
        onTertiary: AppColors.appBg,
        tertiaryContainer: AppColors.badgeBg,
        onTertiaryContainer: AppColors.textSecondary,
        error: AppColors.error,
        onError: AppColors.appBg,
        surface: AppColors.appBg,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.glassBorder,
        outlineVariant: AppColors.glassBg,
        surfaceContainerLowest: AppColors.appBg,
        surfaceContainerLow: AppColors.glassBg,
        surfaceContainer: AppColors.glassBg,
        surfaceContainerHigh: AppColors.badgeBg,
        surfaceContainerHighest: AppColors.badgeBg,
        inverseSurface: AppColors.textSecondary,
        onInverseSurface: AppColors.appBg,
        inversePrimary: AppColors.iceBlue,
        surfaceTint: Color(0x00000000),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  static const SystemUiOverlayStyle _overlay = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.appBg,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get dark {
    final scheme = _scheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.appBg,
      canvasColor: AppColors.appBg,
      cardColor: AppColors.glassBg,
      applyElevationOverlayColor: false,
      splashColor: AppColors.iceBlueHover,
      highlightColor: AppColors.iceBlueGlow,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.iceBlue),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.glassBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Color(0x00000000),
        systemOverlayStyle: _overlay,
        iconTheme: IconThemeData(color: AppColors.iceBlue),
        actionsIconTheme: IconThemeData(color: AppColors.iceBlue),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassBg,
        elevation: 0,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.iceBlue,
          foregroundColor: AppColors.onPrimary,
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
          foregroundColor: AppColors.iceBlue,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.iceBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.iceBlue,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIconColor: AppColors.iceBlue,
        suffixIconColor: AppColors.textDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.iceBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textDim),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        selectedColor: AppColors.chipSelectedBg,
        labelStyle: const TextStyle(color: AppColors.chipFg),
        secondaryLabelStyle: const TextStyle(color: AppColors.chipSelectedFg),
        checkmarkColor: AppColors.iceBlue,
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.glassBg,
        indicatorColor: AppColors.iceBlueGlow,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.iceBlue : AppColors.textDim,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.iceBlue : AppColors.textDim,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.glassBg,
        selectedItemColor: AppColors.iceBlue,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.iceBlue,
        foregroundColor: AppColors.onPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.badgeBg,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.iceBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0F172A),
        surfaceTintColor: const Color(0x00000000),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.iceBlue
              : AppColors.textDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.iceBlueHover
              : AppColors.glassBg;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.glassBorder),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.iceBlue,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.iceBlue,
        selectionColor: AppColors.iceBlueHover,
        selectionHandleColor: AppColors.iceBlue,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textMuted),
        bodySmall: TextStyle(color: AppColors.textDim),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
