import 'package:flutter/material.dart';
import 'package:ma_water/data/models/enums.dart';

/// Centralized color tokens for the "Mā" app.
///
/// Monochrome black-ink-on-white-canvas editorial system: pure ink (#000) on
/// pure canvas (#fff), FLAT (no shadows, no gradients), depth carried by 1px
/// hairline borders plus oversized pastel color blocks. Weight (not gray)
/// carries hierarchy.
///
/// Never hard-code colors in widgets — always reference [AppColors].
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Core monochrome
  // ---------------------------------------------------------------------------
  static const Color ink = Color(0xFF000000);
  static const Color canvas = Color(0xFFFFFFFF);

  // Surfaces (canvas-based; depth comes from hairlines + color blocks)
  static const Color bg = canvas;
  static const Color card = canvas;
  static const Color hairline = Color(0xFFE6E6E6);
  static const Color hairlineSoft = Color(0xFFF1F1F1);
  static const Color surfaceSoft = Color(0xFFF7F7F5);

  /// Default 1px stroke. Repointed to [hairline].
  static const Color line = hairline;

  // Secondary ink — used sparingly; hierarchy should come from weight, not gray.
  static const Color slate = Color(0xFF3A3A3A);

  // ---------------------------------------------------------------------------
  // Pastel color blocks (the depth device)
  // ---------------------------------------------------------------------------
  static const Color blockLime = Color(0xFFDCEEB1);
  static const Color blockLilac = Color(0xFFC5B0F4);
  static const Color blockCream = Color(0xFFF4ECD6);
  static const Color blockPink = Color(0xFFEFD4D4);
  static const Color blockMint = Color(0xFFC8E6CD);
  static const Color blockCoral = Color(0xFFF3C9B6);
  static const Color blockNavy = Color(0xFF1F1D3D);

  /// Single saturated promo accent. Use scarcely — one per page.
  static const Color accentMagenta = Color(0xFFFF3D8B);

  // ---------------------------------------------------------------------------
  // Status (foreground glyph + pastel-block tint background)
  // ---------------------------------------------------------------------------
  static const Color ok = Color(0xFF1EA64A);
  static const Color okBg = blockMint;
  static const Color warn = Color(0xFFB26B00);
  static const Color warnBg = blockCoral;
  static const Color danger = Color(0xFFD8324F);
  static const Color dangerBg = blockPink;

  // ---------------------------------------------------------------------------
  // Legacy aliases (repointed into the monochrome system so callers compile)
  // ---------------------------------------------------------------------------
  static const Color teal = ink;
  static const Color tealDark = Color(0xFF1A1A1A);
  static const Color aqua = ink;
  static const Color mint = surfaceSoft;
  static const Color mint2 = hairline;
  static const Color sky = surfaceSoft;

  // ---------------------------------------------------------------------------
  // Gradients — FLAT: every gradient resolves to solid ink.
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [ink, ink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Flat ink palette. Drives the (now monochrome) animated gradient kit
  /// (AnimatedGradient / GradientText / GradientIcon / ThinkingIndicator).
  static const List<Color> geminiColors = [ink, ink, ink, ink];

  static const LinearGradient geminiGradient = LinearGradient(
    colors: [ink, ink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Flat ink palette (full-spectrum accent neutralized to ink).
  static const List<Color> rainbowColors = [ink, ink];

  static const LinearGradient rainbowGradient = LinearGradient(
    colors: rainbowColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Foreground status color for a [StationStatus].
  static Color statusColor(StationStatus s) {
    switch (s) {
      case StationStatus.normal:
        return ok;
      case StationStatus.warning:
        return warn;
      case StationStatus.danger:
        return danger;
    }
  }

  /// Background (tint) status color for a [StationStatus].
  static Color statusBg(StationStatus s) {
    switch (s) {
      case StationStatus.normal:
        return okBg;
      case StationStatus.warning:
        return warnBg;
      case StationStatus.danger:
        return dangerBg;
    }
  }
}
