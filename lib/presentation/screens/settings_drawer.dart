import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/conversation/conversation_bloc.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.titleMedium,
                            children: const [
                              TextSpan(text: 'Veyra AI '),
                              TextSpan(
                                text: 'Assistant',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        Text('Your intelligent companion', style: AppTypography.labelSmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Profile Section
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                String name = 'User';
                String? pic;
                if (state is SettingsReady) {
                  name = state.profileName.isNotEmpty ? state.profileName : 'User';
                  pic = state.profilePicture.isNotEmpty ? state.profilePicture : null;
                }
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          radius: 24,
                          backgroundImage: pic != null ? FileImage(File(pic)) : null,
                          child: pic == null ? Text(
                            name[0].toUpperCase(),
                            style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                          ) : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTypography.titleMedium),
                            Text('veyra@assistant', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
            
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  final themeMode = state is SettingsReady ? state.themeMode : ThemeMode.system;
                  final palette = state is SettingsReady ? state.palette : AppPalette.emerald;
                  final fontSize = state is SettingsReady ? state.fontSize : AppFontSize.medium;
                  final aiModel = state is SettingsReady ? state.config.modelName : 'Loading...';

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSectionTitle('Appearance'),
                      _buildListTile(Icons.dark_mode_outlined, 'Theme', trailingText: _themeName(themeMode), onTap: () => _showThemeDialog(context, themeMode)),
                      _buildListTile(Icons.color_lens_outlined, 'Color Palette', trailingText: _paletteName(palette), onTap: () => _showPaletteDialog(context, palette)),
                      _buildListTile(Icons.text_fields, 'Font Size', trailingText: _fontSizeName(fontSize), onTap: () => _showFontSizeDialog(context, fontSize)),
                      
                      const SizedBox(height: AppSpacing.sm),
                      _buildSectionTitle('AI & Data'),
                      _buildListTile(Icons.memory, 'AI Model', trailingText: aiModel, onTap: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      }),
                      _buildListTile(Icons.key_outlined, 'API Keys', onTap: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      }),
                      _buildListTile(Icons.storage_outlined, 'Data & Storage', onTap: () {
                        Navigator.pop(context);
                        context.push('/privacy');
                      }),

                      const SizedBox(height: AppSpacing.sm),
                      _buildSectionTitle('App'),
                      _buildListTile(Icons.language, 'Language', trailingText: 'English'),
                      _buildListTile(Icons.notifications_outlined, 'Notifications'),
                      _buildListTile(Icons.security, 'Privacy & Security', onTap: () {
                        Navigator.pop(context);
                        context.push('/privacy');
                      }),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.body),
      trailing: trailingText != null 
          ? Text(trailingText, style: AppTypography.bodySmall) 
          : Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      dense: true,
      onTap: onTap ?? () {},
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String _paletteName(AppPalette palette) => switch (palette) {
    AppPalette.emerald => 'Emerald',
    AppPalette.ocean => 'Ocean',
    AppPalette.violet => 'Violet',
    AppPalette.sunset => 'Sunset',
    AppPalette.rose => 'Rose',
  };

  String _fontSizeName(AppFontSize size) => switch (size) {
    AppFontSize.small => 'Small',
    AppFontSize.medium => 'Medium',
    AppFontSize.large => 'Large',
  };

  void _showThemeDialog(BuildContext context, ThemeMode current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Theme', style: AppTypography.titleLarge),
        children: ThemeMode.values.map((mode) {
          return RadioListTile<ThemeMode>(
            title: Text(_themeName(mode), style: AppTypography.body),
            value: mode,
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                context.read<SettingsBloc>().add(SettingsThemeChanged(val));
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showPaletteDialog(BuildContext context, AppPalette current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Color Palette', style: AppTypography.titleLarge),
        children: AppPalette.values.map((p) {
          return RadioListTile<AppPalette>(
            title: Text(_paletteName(p), style: AppTypography.body),
            value: p,
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                context.read<SettingsBloc>().add(SettingsPaletteChanged(val));
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, AppFontSize current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Font Size', style: AppTypography.titleLarge),
        children: AppFontSize.values.map((s) {
          return RadioListTile<AppFontSize>(
            title: Text(_fontSizeName(s), style: AppTypography.body),
            value: s,
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                context.read<SettingsBloc>().add(SettingsFontSizeChanged(val));
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

}
