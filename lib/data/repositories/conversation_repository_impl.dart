import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../core/error/app_error.dart';
import '../datasources/hive_conversation_source.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final HiveConversationSource _source;
  const ConversationRepositoryImpl(this._source);

  @override
  Future<(List<Conversation>, AppError?)> getConversations() =>
      _source.getConversations();

  @override
  Future<(Conversation?, AppError?)> getConversation(String id) =>
      _source.getConversation(id);

  @override
  Future<(Conversation?, AppError?)> createConversation(String title) =>
      _source.createConversation(title);

  @override
  Future<AppError?> updateConversationTitle(String id, String title, {bool isManuallySet = false}) =>
      _source.updateConversationTitle(id, title, isManuallySet: isManuallySet);

  @override
  Future<AppError?> deleteConversation(String id) =>
      _source.deleteConversation(id);

  @override
  Future<(List<Message>, AppError?)> getMessages(String conversationId) =>
      _source.getMessages(conversationId);

  @override
  Future<(Message?, AppError?)> addMessage(Message message) =>
      _source.addMessage(message);
}
