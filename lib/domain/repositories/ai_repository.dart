import '../entities/ai_provider_config.dart';
import '../entities/message.dart';
import '../entities/attachment.dart';
import '../../core/error/app_error.dart';

abstract class AIRepository {
  Future<(String?, AppError?)> sendMessage({
    required List<Message> history,
    required String userMessage,
    required AIProviderConfig config,
    required String apiKey,
    List<Attachment> attachments = const [],
  });
}
