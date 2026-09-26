import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  void _getStarted() {
    final key = _keyCtrl.text.trim();
    if (key.isNotEmpty) {
      final config = const AIProviderConfig(
        provider: AIProvider.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        modelName: 'gemini-1.5-flash',
      );
      context.read<SettingsBloc>().add(SettingsProviderChanged(config));
      context.read<SettingsBloc>().add(SettingsApiKeySaved(AIProvider.gemini, key));
    }
    
    // Set onboarded flag and navigate (defaults to Veyra Free if no key provided)
    Hive.box('app_settings').put('hasOnboarded', true);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.mintGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: AppSpacing.xl),
                
                SizedBox(
                  height: 40,
                  child: DefaultTextStyle(
                    style: AppTypography.display,
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText('Veyra AI', speed: const Duration(milliseconds: 100)),
                      ],
                      isRepeatingAnimation: false,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                _buildFeatureCard(Icons.auto_awesome, 'Powered by AI', 'Chat with Gemini, GPT, and more', 0),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureCard(Icons.lock_outline, 'Secure & Private', 'API keys stored locally in Keystore', 1),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureCard(Icons.flash_on, 'Free Forever', 'Use Veyra Free without an API key', 2),
                
                const Spacer(),
                
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: Text('Get Free API Key'),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: AppSpacing.md),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.inputRadius,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: TextField(
                    controller: _keyCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Enter API Key (Optional)',
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                      prefixIcon: Icon(Icons.key, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: AppSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _getStarted,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                    ),
                    child: Text('Get Started', style: AppTypography.button),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, int index) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (400 + (index * 150)).ms).slideX(begin: 0.2, end: 0);
  }
}
