import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/ai_provider_config.dart';
import 'settings_state.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

class SettingsProviderChanged extends SettingsEvent {
  final AIProviderConfig config;
  const SettingsProviderChanged(this.config);
  @override
  List<Object?> get props => [config];
}

class SettingsApiKeySaved extends SettingsEvent {
  final AIProvider provider;
  final String apiKey;
  const SettingsApiKeySaved(this.provider, this.apiKey);
  @override
  List<Object?> get props => [provider, apiKey];
}

class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  const SettingsThemeChanged(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

class SettingsPaletteChanged extends SettingsEvent {
  final AppPalette palette;
  const SettingsPaletteChanged(this.palette);
  @override
  List<Object?> get props => [palette];
}

class SettingsFontSizeChanged extends SettingsEvent {
  final AppFontSize fontSize;
  const SettingsFontSizeChanged(this.fontSize);
  @override
  List<Object?> get props => [fontSize];
}

class SettingsProfileSaved extends SettingsEvent {
  final String profileName;
  final String profilePicture;
  const SettingsProfileSaved(this.profileName, this.profilePicture);
  @override
  List<Object?> get props => [profileName, profilePicture];
}

