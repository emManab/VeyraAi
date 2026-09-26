import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/settings/settings_event.dart';
import '../../presentation/blocs/settings/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  bool _apiKeyObscured = true;
  bool _dirty = false;

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  void _populate(AIProviderConfig config) {
    if (!_dirty) {
      _modelCtrl.text = config.modelName;
      _baseUrlCtrl.text = config.baseUrl;
    }
  }

  void _save(BuildContext context, AIProvider provider) {
    final modelName = _modelCtrl.text.trim();
    final baseUrl = _baseUrlCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();

    final config = AIProviderConfig(
      provider: provider,
      modelName: modelName.isEmpty ? _defaultModel(provider) : modelName,
      baseUrl: baseUrl.isEmpty ? _defaultBaseUrl(provider) : baseUrl,
    );
    context.read<SettingsBloc>().add(SettingsProviderChanged(config));
    if (apiKey.isNotEmpty) {
      context.read<SettingsBloc>().add(SettingsApiKeySaved(provider, apiKey));
    }
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _defaultModel(AIProvider provider) => switch (provider) {
        AIProvider.openai => 'gpt-4o-mini',
        AIProvider.gemini => 'gemini-1.5-flash',
        AIProvider.openaiCompatible => 'gpt-3.5-turbo',
        AIProvider.veyraFree => 'openai',
      };

  String _defaultBaseUrl(AIProvider provider) => switch (provider) {
        AIProvider.openai => 'https://api.openai.com/v1',
        AIProvider.gemini => 'https://generativelanguage.googleapis.com/v1beta',
        AIProvider.openaiCompatible => '',
        AIProvider.veyraFree => 'https://text.pollinations.ai/',
      };

  String _providerLabel(AIProvider p) => switch (p) {
        AIProvider.veyraFree => 'Veyra Free',
        AIProvider.openai => 'OpenAI',
        AIProvider.gemini => 'Google Gemini',
        AIProvider.openaiCompatible => 'Custom API',
      };

  Future<void> _launchUrl(String urlStr) async {
    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsReady) _populate(state.config);
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentProvider = state is SettingsReady ? state.config.provider : AIProvider.openai;

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding.copyWith(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                _buildProviderSection(currentProvider, context),
                const SizedBox(height: AppSpacing.lg),
                _buildModelSection(currentProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildApiKeySection(currentProvider, context),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _save(context, currentProvider),
                  icon: Icon(Icons.save_outlined),
                  label: Text('Save Settings', style: AppTypography.button),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.xxl),
                _buildAboutCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderSection(AIProvider currentProvider, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Provider', style: AppTypography.sectionHeader),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AIProvider.values.map((p) {
              final isSelected = p == currentProvider;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    _providerLabel(p),
                    style: isSelected ? AppTypography.chipSelected : AppTypography.chip,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  side: isSelected ? BorderSide.none : BorderSide(color: AppColors.border),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.surfaceDarkCard 
                      : AppColors.surfaceWhite,
                  onSelected: (selected) {
                    if (selected && p != currentProvider) {
                      setState(() => _dirty = true);
                      final modelName = _modelCtrl.text.trim();
                      final baseUrl = _baseUrlCtrl.text.trim();
                      context.read<SettingsBloc>().add(
                            SettingsProviderChanged(
                              AIProviderConfig(
                                provider: p,
                                modelName: modelName.isEmpty ? _defaultModel(p) : modelName,
                                baseUrl: baseUrl.isEmpty ? _defaultBaseUrl(p) : baseUrl,
                              ),
                            ),
                          );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildModelSection(AIProvider currentProvider) {
    final isVeyraFree = currentProvider == AIProvider.veyraFree;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(currentProvider),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Model Configuration', style: AppTypography.sectionHeader),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelCtrl,
            enabled: !isVeyraFree,
            decoration: InputDecoration(
              labelText: 'Model name',
              hintText: 'e.g. gpt-4o-mini, gemini-1.5-flash',
              prefixIcon: const Icon(Icons.memory),
              filled: isVeyraFree,
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          if (currentProvider == AIProvider.openaiCompatible || currentProvider == AIProvider.veyraFree) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _baseUrlCtrl,
              enabled: !isVeyraFree,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://your-endpoint.com/v1',
                prefixIcon: const Icon(Icons.link),
                filled: isVeyraFree,
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() => _dirty = true),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildApiKeySection(AIProvider currentProvider, BuildContext context) {
    if (currentProvider == AIProvider.veyraFree) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Authentication', style: AppTypography.sectionHeader),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.cardRadius,
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'No API key required for Veyra Free.',
                    style: AppTypography.body.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Authentication', style: AppTypography.sectionHeader),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _apiKeyCtrl,
          obscureText: _apiKeyObscured,
          decoration: InputDecoration(
            labelText: 'API key',
            hintText: 'Stored securely in Keystore',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(
                _apiKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
            ),
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your API key is encrypted using AES and Android Keystore. It is never logged or shared.',
          style: AppTypography.caption,
        ),
        if (currentProvider == AIProvider.gemini || currentProvider == AIProvider.openai) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (currentProvider == AIProvider.gemini) {
                  _launchUrl('https://aistudio.google.com/app/apikey');
                } else if (currentProvider == AIProvider.openai) {
                  _launchUrl('https://platform.openai.com/api-keys');
                }
              },
              icon: Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
              label: Text(
                'Get Free API Key',
                style: AppTypography.buttonSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ]
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAboutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Veyra AI', style: AppTypography.titleLarge),
          const SizedBox(height: 2),
          Text('Version 1.0.0', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Built with Flutter. Powered by multiple AI engines.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
