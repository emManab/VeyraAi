import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/blocs/settings/settings_state.dart';
import 'app_colors.dart';

/// Centralized typography styles for Veyra AI.
/// All text styles use Inter font family via Google Fonts.
///
/// Usage: `AppTypography.heading1`, `AppTypography.body`, etc.
class AppTypography {
  AppTypography._();
  
  static double _scale = 1.0;
  
  static void applyFontSize(AppFontSize size) {
    switch (size) {
      case AppFontSize.small: _scale = 0.85; break;
      case AppFontSize.medium: _scale = 1.0; break;
      case AppFontSize.large: _scale = 1.15; break;
    }
  }

  // ── Display / Hero ──
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32 * _scale,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ── Headings ──
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 28 * _scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 22 * _scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 18 * _scale,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Title ──
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 20 * _scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16 * _scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14 * _scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Body ──
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16 * _scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14 * _scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13 * _scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ── Label ──
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14 * _scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12 * _scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11 * _scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ── Caption ──
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12 * _scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ── Button ──
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15 * _scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textOnPrimary,
        height: 1.4,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 13 * _scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.4,
      );

  // ── App Bar Title ──
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 20 * _scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ── Section Headers ──
  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 16 * _scale,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Greeting ──
  static TextStyle get greetingLabel => GoogleFonts.inter(
        fontSize: 12 * _scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get greetingName => GoogleFonts.inter(
        fontSize: 36 * _scale,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ── Chip ──
  static TextStyle get chip => GoogleFonts.inter(
        fontSize: 13 * _scale,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get chipSelected => GoogleFonts.inter(
        fontSize: 13 * _scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.4,
      );

  // ── Timestamp ──
  static TextStyle get timestamp => GoogleFonts.inter(
        fontSize: 12 * _scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ── Nav Label ──
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 11 * _scale,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );
}
