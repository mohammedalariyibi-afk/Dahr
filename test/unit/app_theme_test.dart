import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/theme/app_colors.dart';
import 'package:dahr/core/theme/app_theme.dart';

void main() {
  group('Stitch Ice Blue / Slate 950 tokens', () {
    test('source-of-truth hex and rgba values', () {
      expect(AppColors.iceBlue, const Color(0xFF7DD3FC));
      expect(
        AppColors.iceBlueGlow,
        const Color.fromRGBO(125, 211, 252, 0.1),
      );
      expect(
        AppColors.iceBlueHover,
        const Color.fromRGBO(125, 211, 252, 0.2),
      );
      expect(AppColors.appBg, const Color(0xFF020617));
      expect(
        AppColors.badgeBg,
        const Color.fromRGBO(15, 23, 42, 0.8),
      );
      expect(
        AppColors.glassBg,
        const Color.fromRGBO(255, 255, 255, 0.05),
      );
      expect(
        AppColors.glassBorder,
        const Color.fromRGBO(255, 255, 255, 0.10),
      );
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textSecondary, const Color(0xFFE2E8F0));
      expect(AppColors.textMuted, const Color(0xFFCBD5E1));
      expect(AppColors.textDim, const Color(0xFF94A3B8));
    });

    test('retired cream / burgundy / gold hexes are not the live tokens', () {
      const retired = <Color>[
        Color(0xFFF7F1E8),
        Color(0xFFEDE4D6),
        Color(0xFF6B1E2F),
        Color(0xFFC4A35A),
        Color(0xFF0B1214),
        Color(0xFF0F5C57),
      ];

      expect(retired, isNot(contains(AppColors.iceBlue)));
      expect(retired, isNot(contains(AppColors.appBg)));
      expect(retired, isNot(contains(AppColors.cream)));
      expect(retired, isNot(contains(AppColors.burgundy)));
      expect(retired, isNot(contains(AppColors.gold)));
    });

    test('legacy screen aliases remap onto the Stitch tokens', () {
      expect(AppColors.cream, AppColors.appBg);
      expect(AppColors.creamDark, AppColors.glassBg);
      expect(AppColors.surface, AppColors.glassBg);
      expect(AppColors.burgundy, AppColors.iceBlue);
      expect(AppColors.gold, AppColors.iceBlue);
      expect(AppColors.ink, AppColors.textPrimary);
      expect(AppColors.inkMuted, AppColors.textMuted);
      expect(AppColors.inkFaint, AppColors.textDim);
      expect(AppColors.border, AppColors.glassBorder);
      expect(AppColors.onBurgundy, AppColors.onPrimary);
      expect(AppColors.star, AppColors.iceBlue);
    });
  });

  group('AppTheme.dark', () {
    test('is a dark ColorScheme on Slate 950 with ice-blue accent', () {
      final theme = AppTheme.dark;
      final scheme = theme.colorScheme;

      expect(theme.brightness, Brightness.dark);
      expect(scheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.appBg);
      expect(scheme.primary, AppColors.iceBlue);
      expect(scheme.onPrimary, AppColors.onPrimary);
      expect(scheme.surface, AppColors.appBg);
      expect(scheme.onSurface, AppColors.textPrimary);
      expect(scheme.error, AppColors.error);
    });

    test('cards, app bars, and inputs use glass fill and glass border', () {
      final theme = AppTheme.dark;
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;

      expect(theme.cardTheme.color, AppColors.glassBg);
      expect(cardShape.side.color, AppColors.glassBorder);
      expect(theme.appBarTheme.backgroundColor, AppColors.glassBg);
      expect(theme.inputDecorationTheme.fillColor, AppColors.glassBg);
      expect(
        (theme.inputDecorationTheme.enabledBorder as OutlineInputBorder)
            .borderSide
            .color,
        AppColors.glassBorder,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder as OutlineInputBorder)
            .borderSide
            .color,
        AppColors.iceBlue,
      );
    });

    test('status bar icons are light-on-dark', () {
      final overlay = AppTheme.dark.appBarTheme.systemOverlayStyle!;
      expect(overlay.statusBarIconBrightness, Brightness.light);
      expect(overlay.statusBarBrightness, Brightness.dark);
      expect(
        overlay.systemNavigationBarIconBrightness,
        Brightness.light,
      );
    });

    test('active tab and search use ice blue', () {
      final theme = AppTheme.dark;
      expect(
        theme.bottomNavigationBarTheme.selectedItemColor,
        AppColors.iceBlue,
      );
      expect(theme.inputDecorationTheme.prefixIconColor, AppColors.iceBlue);
      expect(theme.progressIndicatorTheme.color, AppColors.iceBlue);
    });
  });
}
