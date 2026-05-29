import 'package:flutter/material.dart';
import 'package:ma_water/data/models/enums.dart';

/// Centralized color tokens for the "Mā" app.
///
/// Never hard-code colors in widgets — always reference [AppColors].
class AppColors {
  AppColors._();

  // Neutrals / surfaces
  static const Color ink = Color(0xFF0D2B3E);
  static const Color slate = Color(0xFF5A7283);
  static const Color line = Color(0xFFE4EDF2);
  static const Color bg = Color(0xFFF6FAFB);
  static const Color card = Color(0xFFFFFFFF);

  // Brand
  static const Color teal = Color(0xFF0D9AA6);
  static const Color tealDark = Color(0xFF077C87);
  static const Color aqua = Color(0xFF19BCD1);
  static const Color mint = Color(0xFFE6FBFA);
  static const Color mint2 = Color(0xFFD5F3F5);
  static const Color sky = Color(0xFFEEF7FB);

  // Status
  static const Color ok = Color(0xFF16A575);
  static const Color okBg = Color(0xFFE3F7EF);
  static const Color warn = Color(0xFFE8832F);
  static const Color warnBg = Color(0xFFFDEFE1);
  static const Color danger = Color(0xFFE0445F);
  static const Color dangerBg = Color(0xFFFCE8EB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [teal, aqua],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Google-Gemini-style palette, blended with the water brand:
  /// teal -> aqua -> blue -> purple. Drives the animated gradient kit
  /// (AnimatedGradient / GradientText / GradientIcon / ThinkingIndicator).
  static const List<Color> geminiColors = [
    Color(0xFF0D9AA6),
    Color(0xFF19BCD1),
    Color(0xFF4F8CFF),
    Color(0xFF8A6CFF),
  ]; // teal->aqua->blue->purple

  static const LinearGradient geminiGradient = LinearGradient(
    colors: geminiColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Google-Gemini-style rainbow palette: blue -> purple -> red -> amber ->
  /// green. Used by GradientText / GradientIcon for the full-spectrum accent.
  static const List<Color> rainbowColors = [
    Color(0xFF4285F4),
    Color(0xFF9B72F2),
    Color(0xFFD96570),
    Color(0xFFF2A60C),
    Color(0xFF34A853),
  ]; // Google blue->purple->red->amber->green

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
