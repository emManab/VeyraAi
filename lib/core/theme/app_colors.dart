import 'package:flutter/material.dart';
import '../../presentation/blocs/settings/settings_state.dart';

/// Centralized color palette for Veyra AI.
class AppColors {
  AppColors._();

  // ── Brand Primary (Mutable for dynamic palettes) ──
  static Color primary = const Color(0xFF0D5C3F);       
  static Color primaryLight = const Color(0xFF10B981);   
  static Color primaryDark = const Color(0xFF064E3B);    

  // ── Mint / Accent ──
  static Color mint = const Color(0xFFD1FAE5);           
  static Color mintLight = const Color(0xFFECFDF5);      
  static Color mintDark = const Color(0xFFA7F3D0);       

  // ── Surface / Background ──
  static const Color surface = Color(0xFFFAFBFC);        
  static const Color surfaceWhite = Color(0xFFFFFFFF);   
  static const Color surfaceDark = Color(0xFF111827);     
  static const Color surfaceDarkCard = Color(0xFF1F2937); 

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A2B3C);    
  static const Color textSecondary = Color(0xFF6B7280);  
  static const Color textTertiary = Color(0xFF9CA3AF);   
  static const Color textOnPrimary = Color(0xFFFFFFFF);  
  static const Color textDarkPrimary = Color(0xFFF9FAFB);  
  static const Color textDarkSecondary = Color(0xFF9CA3AF); 

  // ── Navigation ──
  static Color get navActive => primary;     
  static const Color navInactive = Color(0xFF9CA3AF);    
  static const Color navBackground = Color(0xFFFFFFFF);  
  static const Color navDarkBackground = Color(0xFF1F2937);

  // ── Greeting Card ──
  static Color greetingStart = const Color(0xFFF0FDF4);  
  static Color greetingEnd = const Color(0xFFDCFCE7);    

  // ── Category Icons ──
  static const Color categoryCode = Color(0xFF0D5C3F);
  static const Color categoryIdea = Color(0xFF7C3AED);
  static const Color categoryBook = Color(0xFF2563EB);
  static const Color categoryDoc = Color(0xFFF59E0B);
  static const Color categoryChat = Color(0xFFEF4444);
  static const Color categoryTravel = Color(0xFFEC4899);
  static const Color categoryFitness = Color(0xFF10B981);
  static const Color categoryStar = Color(0xFFF59E0B);

  // ── Featured Prompt Cards ──
  static Color get promptCardGreen => primary;
  static const Color promptCardBeige = Color(0xFFF5F0E8);
  static const Color promptCardGray = Color(0xFFEFF1F3);

  // ── Borders / Dividers ──
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFF374151);

  // ── Semantic ──
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Shadows (colors only — use with BoxShadow) ──
  static const Color shadowLight = Color(0x0D000000);    
  static const Color shadowMedium = Color(0x1A000000);   
  static Color get shadowPrimary => primary.withValues(alpha: 0.2);  

  // ── Gradients ──
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get mintGradient => LinearGradient(
    colors: [mintLight, mint],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get greetingGradient => LinearGradient(
    colors: [greetingStart, greetingEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get surfaceGradient => LinearGradient(
    colors: [surfaceWhite, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get userBubbleGradient => LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static void applyPalette(AppPalette palette) {
    switch (palette) {
      case AppPalette.emerald:
        primary = const Color(0xFF0D5C3F);
        primaryLight = const Color(0xFF10B981);
        primaryDark = const Color(0xFF064E3B);
        mint = const Color(0xFFD1FAE5);
        mintLight = const Color(0xFFECFDF5);
        mintDark = const Color(0xFFA7F3D0);
        greetingStart = const Color(0xFFF0FDF4);
        greetingEnd = const Color(0xFFDCFCE7);
        break;
      case AppPalette.ocean:
        primary = const Color(0xFF0F4C81);
        primaryLight = const Color(0xFF3B82F6);
        primaryDark = const Color(0xFF1E3A8A);
        mint = const Color(0xFFDBEAFE);
        mintLight = const Color(0xFFEFF6FF);
        mintDark = const Color(0xFFBFDBFE);
        greetingStart = const Color(0xFFEFF6FF);
        greetingEnd = const Color(0xFFDBEAFE);
        break;
      case AppPalette.violet:
        primary = const Color(0xFF5B21B6);
        primaryLight = const Color(0xFF8B5CF6);
        primaryDark = const Color(0xFF4C1D95);
        mint = const Color(0xFFEDE9FE);
        mintLight = const Color(0xFFF5F3FF);
        mintDark = const Color(0xFFDDD6FE);
        greetingStart = const Color(0xFFF5F3FF);
        greetingEnd = const Color(0xFFEDE9FE);
        break;
      case AppPalette.sunset:
        primary = const Color(0xFFC2410C);
        primaryLight = const Color(0xFFF97316);
        primaryDark = const Color(0xFF9A3412);
        mint = const Color(0xFFFFEDD5);
        mintLight = const Color(0xFFFFF7ED);
        mintDark = const Color(0xFFFED7AA);
        greetingStart = const Color(0xFFFFF7ED);
        greetingEnd = const Color(0xFFFFEDD5);
        break;
      case AppPalette.rose:
        primary = const Color(0xFFBE123C);
        primaryLight = const Color(0xFFF43F5E);
        primaryDark = const Color(0xFF9F1239);
        mint = const Color(0xFFFFE4E6);
        mintLight = const Color(0xFFFFF1F2);
        mintDark = const Color(0xFFFECDD3);
        greetingStart = const Color(0xFFFFF1F2);
        greetingEnd = const Color(0xFFFFE4E6);
        break;
    }
  }
}
