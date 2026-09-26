import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../core/error/app_error.dart';

class HiveSettingsSource {
  static const _providerKey = 'provider';
  static const _baseUrlKey = 'base_url';
  static const _modelKey = 'model_name';

  final FlutterSecureStorage _secure;

  const HiveSettingsSource(this._secure);

  String _apiKeyFor(AIProvider provider) => 'api_key_${provider.name}';

  Future<(AIProviderConfig?, AppError?)> getProviderConfig() async {
    try {
      final providerStr = await _secure.read(key: _providerKey);
      final baseUrl = await _secure.read(key: _baseUrlKey);
      final model = await _secure.read(key: _modelKey);

      if (providerStr == null || baseUrl == null || model == null) {
        return (AIProviderConfig.defaultConfig, null);
      }

      final provider = AIProvider.values.firstWhere(
        (p) => p.name == providerStr,
        orElse: () => AIProvider.veyraFree,
      );

      return (
        AIProviderConfig(
            provider: provider, baseUrl: baseUrl, modelName: model),
        null
      );
    } catch (_) {
      return (AIProviderConfig.defaultConfig, null);
    }
  }

  Future<AppError?> saveProviderConfig(AIProviderConfig config) async {
    try {
      await _secure.write(key: _providerKey, value: config.provider.name);
      await _secure.write(key: _baseUrlKey, value: config.baseUrl);
      await _secure.write(key: _modelKey, value: config.modelName);
      return null;
    } catch (_) {
      return const StorageError('Failed to save provider config.');
    }
  }

  Future<(String?, AppError?)> getApiKey(AIProvider provider) async {
    try {
      final key = await _secure.read(key: _apiKeyFor(provider));
      return (key, null);
    } catch (_) {
      return (null, const StorageError('Failed to read API key.'));
    }
  }

  Future<AppError?> saveApiKey(AIProvider provider, String apiKey) async {
    try {
      await _secure.write(key: _apiKeyFor(provider), value: apiKey);
      return null;
    } catch (_) {
      return const StorageError('Failed to save API key.');
    }
  }

  Future<(Map<String, dynamic>?, AppError?)> getAppAppearance() async {
    try {
      final box = Hive.box('app_settings');
      final themeMode = box.get('themeMode', defaultValue: 'system') as String;
      final palette = box.get('palette', defaultValue: 'emerald') as String;
      final fontSize = box.get('fontSize', defaultValue: 'medium') as String;
      return ({'themeMode': themeMode, 'palette': palette, 'fontSize': fontSize}, null);
    } catch (_) {
      return (null, const StorageError('Failed to read appearance settings.'));
    }
  }

  Future<AppError?> saveAppAppearance(String themeMode, String palette, String fontSize) async {
    try {
      final box = Hive.box('app_settings');
      await box.put('themeMode', themeMode);
      await box.put('palette', palette);
      await box.put('fontSize', fontSize);
      return null;
    } catch (_) {
      return const StorageError('Failed to save appearance settings.');
    }
  }

  Future<(Map<String, dynamic>?, AppError?)> getProfile() async {
    try {
      final box = Hive.box('app_settings');
      final name = box.get('profileName', defaultValue: 'Manab') as String;
      final picturePath = box.get('profilePicture', defaultValue: '') as String;
      return ({'name': name, 'picture': picturePath}, null);
    } catch (_) {
      return (null, const StorageError('Failed to read profile.'));
    }
  }

  Future<AppError?> saveProfile(String name, String picturePath) async {
    try {
      final box = Hive.box('app_settings');
      await box.put('profileName', name);
      await box.put('profilePicture', picturePath);
      return null;
    } catch (_) {
      return const StorageError('Failed to save profile.');
    }
  }
}
