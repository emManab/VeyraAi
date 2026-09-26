import '../../domain/entities/ai_provider_config.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../core/error/app_error.dart';
import '../datasources/openai_client.dart';
import '../datasources/gemini_client.dart';
import '../datasources/free_ai_client.dart';

class AIRepositoryImpl implements AIRepository {
  final OpenAIClient _openai;
  final GeminiClient _gemini;
  final FreeAIClient _freeAi;

  const AIRepositoryImpl(this._openai, this._gemini, this._freeAi);

  @override
  Future<(String?, AppError?)> sendMessage({
    required List<Message> history,
    required String userMessage,
    required AIProviderConfig config,
    required String apiKey,
    List<Attachment> attachments = const [],
  }) {
    switch (config.provider) {
      case AIProvider.veyraFree:
        return _freeAi.chat(
          history: history,
          userMessage: userMessage,
        );
      case AIProvider.gemini:
        if (apiKey.trim().isEmpty) {
          return Future.value((null, const AuthError('Connect your API key to use this provider.')));
        }
        return _gemini.chat(
          apiKey: apiKey,
          model: config.modelName,
          history: history,
          userMessage: userMessage,
        );
      case AIProvider.openai:
      case AIProvider.openaiCompatible:
        if (apiKey.trim().isEmpty) {
          return Future.value((null, const AuthError('Connect your API key to use this provider.')));
        }
        return _openai.chat(
          baseUrl: config.baseUrl,
          apiKey: apiKey,
          model: config.modelName,
          history: history,
          userMessage: userMessage,
        );
    }
  }
}
