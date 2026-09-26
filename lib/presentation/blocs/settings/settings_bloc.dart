import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../domain/entities/ai_provider_config.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetProviderConfig _getConfig;
  final SaveProviderConfig _saveConfig;
  final SaveApiKey _saveKey;
  final GetAppAppearance _getAppearance;
  final SaveAppAppearance _saveAppearance;
  final GetProfile _getProfile;
  final SaveProfile _saveProfile;

  SettingsBloc({
    required GetProviderConfig getProviderConfig,
    required SaveProviderConfig saveProviderConfig,
    required SaveApiKey saveApiKey,
    required GetAppAppearance getAppAppearance,
    required SaveAppAppearance saveAppAppearance,
    required GetProfile getProfile,
    required SaveProfile saveProfile,
  })  : _getConfig = getProviderConfig,
        _saveConfig = saveProviderConfig,
        _saveKey = saveApiKey,
        _getAppearance = getAppAppearance,
        _saveAppearance = saveAppAppearance,
        _getProfile = getProfile,
        _saveProfile = saveProfile,
        super(const SettingsInitial()) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsProviderChanged>(_onProviderChanged);
    on<SettingsApiKeySaved>(_onApiKeySaved);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsPaletteChanged>(_onPaletteChanged);
    on<SettingsFontSizeChanged>(_onFontSizeChanged);
    on<SettingsProfileSaved>(_onProfileSaved);
  }

  Future<void> _onLoaded(
      SettingsLoaded event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final (config, err) = await _getConfig();
    final (appearance, appErr) = await _getAppearance();
    final (profile, profErr) = await _getProfile();
    
    if (err != null || appErr != null || profErr != null) {
      emit(SettingsError(err ?? appErr ?? profErr!));
    } else {
      final t = appearance?['themeMode'] as String? ?? 'system';
      final p = appearance?['palette'] as String? ?? 'emerald';
      final f = appearance?['fontSize'] as String? ?? 'medium';
      final n = profile?['name'] as String? ?? 'Manab';
      final pic = profile?['picture'] as String? ?? '';
      
      emit(SettingsReady(
        config: config ?? AIProviderConfig.defaultConfig,
        themeMode: ThemeMode.values.firstWhere((e) => e.name == t, orElse: () => ThemeMode.system),
        palette: AppPalette.values.firstWhere((e) => e.name == p, orElse: () => AppPalette.emerald),
        fontSize: AppFontSize.values.firstWhere((e) => e.name == f, orElse: () => AppFontSize.medium),
        profileName: n,
        profilePicture: pic,
      ));
    }
  }

  Future<void> _onProviderChanged(
    SettingsProviderChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final err = await _saveConfig(event.config);
    if (err != null) {
      emit(SettingsError(err));
    } else if (state is SettingsReady) {
      emit((state as SettingsReady).copyWith(config: event.config, saved: true));
    }
  }

  Future<void> _onApiKeySaved(
    SettingsApiKeySaved event,
    Emitter<SettingsState> emit,
  ) async {
    final err = await _saveKey(event.provider, event.apiKey);
    if (err != null) {
      emit(SettingsError(err));
    } else if (state is SettingsReady) {
      emit((state as SettingsReady).copyWith(saved: true));
    }
  }
  
  Future<void> _onThemeChanged(SettingsThemeChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsReady) {
      final st = state as SettingsReady;
      await _saveAppearance(event.themeMode.name, st.palette.name, st.fontSize.name);
      emit(st.copyWith(themeMode: event.themeMode));
    }
  }
  
  Future<void> _onPaletteChanged(SettingsPaletteChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsReady) {
      final st = state as SettingsReady;
      await _saveAppearance(st.themeMode.name, event.palette.name, st.fontSize.name);
      emit(st.copyWith(palette: event.palette));
    }
  }
  
  Future<void> _onFontSizeChanged(SettingsFontSizeChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsReady) {
      final st = state as SettingsReady;
      await _saveAppearance(st.themeMode.name, st.palette.name, event.fontSize.name);
      emit(st.copyWith(fontSize: event.fontSize));
    }
  }

  Future<void> _onProfileSaved(SettingsProfileSaved event, Emitter<SettingsState> emit) async {
    if (state is SettingsReady) {
      final st = state as SettingsReady;
      await _saveProfile(event.profileName, event.profilePicture);
      emit(st.copyWith(profileName: event.profileName, profilePicture: event.profilePicture));
    }
  }
}
