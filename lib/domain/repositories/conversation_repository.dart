import '../entities/conversation.dart';
import '../entities/message.dart';
import '../../core/error/app_error.dart';

abstract class ConversationRepository {
  Future<(List<Conversation>, AppError?)> getConversations();
  Future<(Conversation?, AppError?)> getConversation(String id);
  Future<(Conversation?, AppError?)> createConversation(String title);
  Future<AppError?> updateConversationTitle(String id, String title, {bool isManuallySet = false});
  Future<AppError?> deleteConversation(String id);
  Future<(List<Message>, AppError?)> getMessages(String conversationId);
  Future<(Message?, AppError?)> addMessage(Message message);
}
