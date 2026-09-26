import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/ai_provider_config.dart';
import '../../../core/error/app_error.dart';

enum AppPalette { emerald, ocean, violet, sunset, rose }
enum AppFontSize { small, medium, large }

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsReady extends SettingsState {
  final AIProviderConfig config;
  final ThemeMode themeMode;
  final AppPalette palette;
  final AppFontSize fontSize;
  final String profileName;
  final String profilePicture;
  final bool saved;

  const SettingsReady({
    required this.config,
    this.themeMode = ThemeMode.system,
    this.palette = AppPalette.emerald,
    this.fontSize = AppFontSize.medium,
    this.profileName = 'Manab',
    this.profilePicture = '',
    this.saved = false,
  });

  SettingsReady copyWith({
    AIProviderConfig? config,
    ThemeMode? themeMode,
    AppPalette? palette,
    AppFontSize? fontSize,
    String? profileName,
    String? profilePicture,
    bool? saved,
  }) {
    return SettingsReady(
      config: config ?? this.config,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      fontSize: fontSize ?? this.fontSize,
      profileName: profileName ?? this.profileName,
      profilePicture: profilePicture ?? this.profilePicture,
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [config, themeMode, palette, fontSize, profileName, profilePicture, saved];
}

class SettingsError extends SettingsState {
  final AppError error;
  const SettingsError(this.error);
  @override
  List<Object?> get props => [error];
}
