import '../entities/ai_provider_config.dart';
import '../../core/error/app_error.dart';

abstract class SettingsRepository {
  Future<(AIProviderConfig?, AppError?)> getProviderConfig();
  Future<AppError?> saveProviderConfig(AIProviderConfig config);
  Future<(String?, AppError?)> getApiKey(AIProvider provider);
  Future<AppError?> saveApiKey(AIProvider provider, String apiKey);
  Future<(Map<String, dynamic>?, AppError?)> getAppAppearance();
  Future<AppError?> saveAppAppearance(String themeMode, String palette, String fontSize);
  Future<(Map<String, dynamic>?, AppError?)> getProfile();
  Future<AppError?> saveProfile(String name, String picturePath);
}
