import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // Navigates to root, GoRouter's redirect logic will handle onboarding check
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: AppColors.primary,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 400.ms),
            
            const SizedBox(height: 32),
            
            RichText(
              text: TextSpan(
                style: AppTypography.display.copyWith(fontSize: 28),
                children: const [
                  TextSpan(text: 'Veyra AI '),
                  TextSpan(
                    text: 'Assistant',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 400.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Your intelligent companion',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            )
            .animate()
            .fadeIn(delay: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 600.ms),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.mintDark,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
