import 'package:flutter/material.dart';

/// Dahr brand palette — Mohammed’s locked Stitch system:
/// Ice Blue glass on Slate 950.
///
/// Use these tokens; do not hardcode cream / burgundy / gold (retired).
abstract final class AppColors {
  // --- Stitch source of truth ---
  static const Color iceBlue = Color(0xFF7DD3FC);
  static const Color iceBlueGlow = Color.fromRGBO(125, 211, 252, 0.1);
  static const Color iceBlueHover = Color.fromRGBO(125, 211, 252, 0.2);
  static const Color appBg = Color(0xFF020617);
  static const Color badgeBg = Color.fromRGBO(15, 23, 42, 0.8);
  static const Color glassBg = Color.fromRGBO(255, 255, 255, 0.05);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFFCBD5E1);
  static const Color textDim = Color(0xFF94A3B8);

  /// Dark ink on ice-blue fills (logos-as-buttons, selected chips, avatars).
  static const Color onPrimary = appBg;

  // --- Semantic (dark-surface) ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color favorite = Color(0xFFF87171);
  static const Color star = iceBlue;
  static const Color skeletonBase = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color skeletonHighlight = iceBlueGlow;
  static const Color chipSelectedBg = iceBlueGlow;
  static const Color chipSelectedFg = iceBlue;
  static const Color chipBg = glassBg;
  static const Color chipFg = textMuted;

  // --- Remapped aliases so existing screens pick up the Stitch look ---
  static const Color cream = appBg;
  static const Color creamDark = glassBg;
  static const Color surface = glassBg;
  static const Color burgundy = iceBlue;
  static const Color burgundyDark = iceBlue;
  static const Color burgundySoft = iceBlueHover;
  static const Color gold = iceBlue;
  static const Color goldLight = iceBlueGlow;
  static const Color goldDark = iceBlue;
  static const Color ink = textPrimary;
  static const Color inkMuted = textMuted;
  static const Color inkFaint = textDim;
  static const Color border = glassBorder;
  static const Color onBurgundy = onPrimary;
  static const Color onGold = onPrimary;
}
