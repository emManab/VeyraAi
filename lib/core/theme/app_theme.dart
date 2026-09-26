import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  // Legacy redirects to keep existing screens compiling during refactor
  static Color get primaryIndigo => AppColors.primary;
  static Color get accentCyan => AppColors.primaryLight;
  static Color get darkSurface => AppColors.surfaceDark;
  static Color get darkSurfaceLight => AppColors.surfaceDarkCard;
  static Color get darkCard => AppColors.surfaceDarkCard;
  static LinearGradient get primaryGradient => AppColors.primaryGradient;
  static LinearGradient get darkBackgroundGradient => AppColors.surfaceGradient; // Approximation for now

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        surfaceContainerHighest: AppColors.surfaceWhite,
        surfaceContainerLow: AppColors.surfaceWhite,
        outlineVariant: AppColors.border,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.appBarTitle,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.heading1,
        headlineMedium: AppTypography.heading2,
        headlineSmall: AppTypography.heading3,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.labelSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: AppSpacing.inputPadding,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        color: AppColors.surfaceWhite,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogRadius,
        ),
        backgroundColor: AppColors.surfaceWhite,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.divider,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.mint,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDarkPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        surfaceContainerHighest: AppColors.surfaceDarkCard,
        surfaceContainerLow: AppColors.surfaceDarkCard.withValues(alpha: 0.5),
        outlineVariant: AppColors.borderDark,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textDarkPrimary,
        titleTextStyle: AppTypography.appBarTitle.copyWith(color: AppColors.textDarkPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.textDarkPrimary),
        headlineLarge: AppTypography.heading1.copyWith(color: AppColors.textDarkPrimary),
        headlineMedium: AppTypography.heading2.copyWith(color: AppColors.textDarkPrimary),
        headlineSmall: AppTypography.heading3.copyWith(color: AppColors.textDarkPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textDarkPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textDarkPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textDarkPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textDarkPrimary),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.textDarkPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textDarkSecondary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textDarkPrimary),
        labelMedium: AppTypography.label.copyWith(color: AppColors.textDarkSecondary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textDarkSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDarkCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: AppSpacing.inputPadding,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        color: AppColors.surfaceDarkCard,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogRadius,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.borderDark,
      ),
    );
  }
}
