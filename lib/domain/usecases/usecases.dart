import 'dart:io';
import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/attachment.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/ai_repository.dart';
import '../repositories/settings_repository.dart';
import '../entities/ai_provider_config.dart';
import '../../core/error/app_error.dart';

class GetConversations {
  final ConversationRepository _repo;
  const GetConversations(this._repo);
  Future<(List<Conversation>, AppError?)> call() => _repo.getConversations();
}

class CreateConversation {
  final ConversationRepository _repo;
  const CreateConversation(this._repo);
  Future<(Conversation?, AppError?)> call(String title) =>
      _repo.createConversation(title);
}

class DeleteConversation {
  final ConversationRepository _repo;
  const DeleteConversation(this._repo);
  Future<AppError?> call(String id) => _repo.deleteConversation(id);
}

class UpdateConversationTitle {
  final ConversationRepository _repo;
  const UpdateConversationTitle(this._repo);
  Future<AppError?> call(String id, String title, {bool isManuallySet = true}) =>
      _repo.updateConversationTitle(id, title, isManuallySet: isManuallySet);
}

class GetMessages {
  final ConversationRepository _repo;
  const GetMessages(this._repo);
  Future<(List<Message>, AppError?)> call(String conversationId) =>
      _repo.getMessages(conversationId);
}

class SendChatMessage {
  final AIRepository _aiRepo;
  final ConversationRepository _convRepo;
  const SendChatMessage(this._aiRepo, this._convRepo);

  Future<(Message?, AppError?)> call({
    required String conversationId,
    required List<Message> history,
    required String userContent,
    required AIProviderConfig config,
    required String apiKey,
    List<Attachment> attachments = const [],
  }) async {
    final now = DateTime.now();
    final userMsg = Message(
      id: '${conversationId}_u_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: MessageRole.user,
      content: userContent,
      createdAt: now,
      attachments: attachments,
    );
    final (_, userSaveErr) = await _convRepo.addMessage(userMsg);
    if (userSaveErr != null) return (null, userSaveErr);

    if (history.isEmpty) {
      final (conv, _) = await _convRepo.getConversation(conversationId);
      if (conv != null && !conv.isTitleManuallySet) {
        String title = userContent;
        if (title.length > 30) {
          title = '${title.substring(0, 30)}...';
        }
        await _convRepo.updateConversationTitle(conversationId, title, isManuallySet: false);
      }
    }

    String finalUserContent = userContent;
    final textAttachments = attachments.where((a) => a.type == AttachmentType.document).toList();
    if (textAttachments.isNotEmpty) {
      finalUserContent += '\n\n--- Attached Documents ---\n';
      for (final a in textAttachments) {
        try {
          final file = File(a.path);
          final content = await file.readAsString();
          finalUserContent += 'Document Name: ${a.name ?? a.path.split('/').last}\n';
          finalUserContent += 'Content:\n$content\n\n';
        } catch (_) {}
      }
    }

    final (reply, err) = await _aiRepo.sendMessage(
      history: history,
      userMessage: finalUserContent,
      config: config,
      apiKey: apiKey,
      attachments: attachments,
    );
    if (err != null) return (null, err);

    final replyTime = DateTime.now();
    final assistantMsg = Message(
      id: '${conversationId}_a_${replyTime.millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: reply!,
      createdAt: replyTime,
    );
    final (saved, saveErr) = await _convRepo.addMessage(assistantMsg);
    if (saveErr != null) return (null, saveErr);
    return (saved, null);
  }
}

class GetProviderConfig {
  final SettingsRepository _repo;
  const GetProviderConfig(this._repo);
  Future<(AIProviderConfig?, AppError?)> call() => _repo.getProviderConfig();
}

class SaveProviderConfig {
  final SettingsRepository _repo;
  const SaveProviderConfig(this._repo);
  Future<AppError?> call(AIProviderConfig config) =>
      _repo.saveProviderConfig(config);
}

class GetApiKey {
  final SettingsRepository _repo;
  const GetApiKey(this._repo);
  Future<(String?, AppError?)> call(AIProvider provider) =>
      _repo.getApiKey(provider);
}

class SaveApiKey {
  final SettingsRepository _repo;
  const SaveApiKey(this._repo);
  Future<AppError?> call(AIProvider provider, String key) =>
      _repo.saveApiKey(provider, key);
}
class GetAppAppearance {
  final SettingsRepository _repo;
  const GetAppAppearance(this._repo);
  Future<(Map<String, dynamic>?, AppError?)> call() => _repo.getAppAppearance();
}

class SaveAppAppearance {
  final SettingsRepository _repo;
  const SaveAppAppearance(this._repo);
  Future<AppError?> call(String themeMode, String palette, String fontSize) =>
      _repo.saveAppAppearance(themeMode, palette, fontSize);
}

class GetProfile {
  final SettingsRepository _repo;
  const GetProfile(this._repo);
  Future<(Map<String, dynamic>?, AppError?)> call() => _repo.getProfile();
}

class SaveProfile {
  final SettingsRepository _repo;
  const SaveProfile(this._repo);
  Future<AppError?> call(String name, String picturePath) => _repo.saveProfile(name, picturePath);
}
