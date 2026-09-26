import 'package:equatable/equatable.dart';

enum AIProvider { veyraFree, openai, gemini, openaiCompatible }

class AIProviderConfig extends Equatable {
  final AIProvider provider;
  final String baseUrl;
  final String modelName;
  // API key is stored separately in secure storage; never held in state.

  const AIProviderConfig({
    required this.provider,
    required this.baseUrl,
    required this.modelName,
  });

  static AIProviderConfig get defaultConfig => const AIProviderConfig(
        provider: AIProvider.veyraFree,
        baseUrl: 'https://text.pollinations.ai/',
        modelName: 'openai',
      );

  AIProviderConfig copyWith({
    AIProvider? provider,
    String? baseUrl,
    String? modelName,
  }) {
    return AIProviderConfig(
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
    );
  }

  @override
  List<Object?> get props => [provider, baseUrl, modelName];
}
