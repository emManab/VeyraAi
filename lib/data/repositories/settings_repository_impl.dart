import '../../domain/entities/ai_provider_config.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../core/error/app_error.dart';
import '../datasources/hive_settings_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final HiveSettingsSource _source;
  const SettingsRepositoryImpl(this._source);

  @override
  Future<(AIProviderConfig?, AppError?)> getProviderConfig() =>
      _source.getProviderConfig();

  @override
  Future<AppError?> saveProviderConfig(AIProviderConfig config) =>
      _source.saveProviderConfig(config);

  @override
  Future<(String?, AppError?)> getApiKey(AIProvider provider) =>
      _source.getApiKey(provider);

  @override
  Future<AppError?> saveApiKey(AIProvider provider, String apiKey) =>
      _source.saveApiKey(provider, apiKey);

  @override
  Future<(Map<String, dynamic>?, AppError?)> getAppAppearance() =>
      _source.getAppAppearance();

  @override
  Future<AppError?> saveAppAppearance(String themeMode, String palette, String fontSize) =>
      _source.saveAppAppearance(themeMode, palette, fontSize);

  @override
  Future<(Map<String, dynamic>?, AppError?)> getProfile() =>
      _source.getProfile();

  @override
  Future<AppError?> saveProfile(String name, String picturePath) =>
      _source.saveProfile(name, picturePath);
}
