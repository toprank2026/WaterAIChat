import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ma_water/core/design/app_colors.dart';

/// Typography tokens for the "Mā" app.
///
/// Headings/labels use Cairo, body copy uses Tajawal. All styles default to
/// [AppColors.ink]; override `color` at the call site when needed.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLg => GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      );

  static TextStyle get displayMd => GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      );

  static TextStyle get titleLg => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      );

  static TextStyle get titleMd => GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get bodyLg => GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get bodyMd => GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  static TextStyle get caption => GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get metric => GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      );
}
