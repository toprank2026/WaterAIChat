import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ma_water/core/design/app_colors.dart';

/// Typography tokens for the "Mā" app.
///
/// Editorial monochrome ramp: the sans (IBM Plex Sans Arabic) carries every
/// headline, title, body, and metric, with weight — not gray — expressing
/// hierarchy and tight negative tracking on the big display sizes. The mono
/// (JetBrains Mono) is reserved strictly for small uppercase eyebrow / caption
/// taxonomy labels, never for reading copy.
///
/// All styles default to [AppColors.ink]; override `color` at the call site
/// when needed.
class AppTextStyles {
  AppTextStyles._();

  /// IBM Plex Sans Arabic — the single editorial voice for all reading type.
  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: AppColors.ink,
      );

  /// JetBrains Mono — taxonomy only (eyebrows / captions), small + uppercase.
  static TextStyle _mono({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: AppColors.ink,
      );

  // --- Display ---------------------------------------------------------------

  static TextStyle get displayLg => _sans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      );

  static TextStyle get displayMd => _sans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
      );

  // --- Titles ----------------------------------------------------------------

  static TextStyle get titleLg => _sans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static TextStyle get titleMd => _sans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // --- Body ------------------------------------------------------------------

  static TextStyle get bodyLg => _sans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodyMd => _sans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  // --- Metric ----------------------------------------------------------------

  static TextStyle get metric => _sans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      );

  // --- Mono taxonomy labels (small, uppercase) -------------------------------

  static TextStyle get caption => _mono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.0,
      );

  static TextStyle get eyebrow => _mono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        height: 1.3,
      );
}
