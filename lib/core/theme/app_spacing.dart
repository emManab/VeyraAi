import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
  static const double colossal = 64.0;

  // Padding presets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);
}

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 100.0;

  // BorderRadius presets
  static BorderRadius get cardRadius => BorderRadius.circular(lg);
  static BorderRadius get chipRadius => BorderRadius.circular(pill);
  static BorderRadius get inputRadius => BorderRadius.circular(md);
  static BorderRadius get buttonRadius => BorderRadius.circular(md);
  static BorderRadius get dialogRadius => BorderRadius.circular(xl);
  static BorderRadius get sheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(24));
  static BorderRadius get navBarRadius =>
      const BorderRadius.vertical(top: Radius.circular(20));
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.shadowPrimary,
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ];
}
