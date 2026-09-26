import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../core/error/app_error.dart';

class HiveConversationSource {
  static const _convBoxName = 'conversations';
  static const _msgBoxName = 'messages';

  final _uuid = const Uuid();

  Box<ConversationModel> get _convBox =>
      Hive.box<ConversationModel>(_convBoxName);
  Box<MessageModel> get _msgBox => Hive.box<MessageModel>(_msgBoxName);

  static Future<void> openBoxes() async {
    await Hive.openBox<ConversationModel>(_convBoxName);
    await Hive.openBox<MessageModel>(_msgBoxName);
  }

  Future<(List<Conversation>, AppError?)> getConversations() async {
    try {
      final convs = _convBox.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return (convs, null);
    } catch (_) {
      return (<Conversation>[], const StorageError());
    }
  }

  Future<(Conversation?, AppError?)> createConversation(String title) async {
    try {
      final now = DateTime.now();
      final model = ConversationModel(
        id: _uuid.v4(),
        title: title,
        isTitleManuallySet: title != 'New Conversation',
        createdAt: now,
        updatedAt: now,
      );
      await _convBox.put(model.id, model);
      return (model.toEntity(), null);
    } catch (_) {
      return (null, const StorageError());
    }
  }

  Future<(Conversation?, AppError?)> getConversation(String id) async {
    try {
      final model = _convBox.get(id);
      if (model == null) return (null, const StorageError('Conversation not found'));
      return (model.toEntity(), null);
    } catch (_) {
      return (null, const StorageError());
    }
  }

  Future<AppError?> updateConversationTitle(String id, String title, {bool isManuallySet = false}) async {
    try {
      final model = _convBox.get(id);
      if (model == null) return null;
      model.title = title;
      if (isManuallySet) {
        model.isTitleManuallySet = true;
      }
      model.updatedAt = DateTime.now();
      await model.save();
      return null;
    } catch (_) {
      return const StorageError();
    }
  }

  Future<AppError?> deleteConversation(String id) async {
    try {
      await _convBox.delete(id);
      final toDelete = _msgBox.values
          .where((m) => m.conversationId == id)
          .map((m) => m.id)
          .toList();
      for (final msgId in toDelete) {
        await _msgBox.delete(msgId);
      }
      return null;
    } catch (_) {
      return const StorageError();
    }
  }

  Future<(List<Message>, AppError?)> getMessages(String conversationId) async {
    try {
      final msgs = _msgBox.values
          .where((m) => m.conversationId == conversationId)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return (msgs, null);
    } catch (_) {
      return (<Message>[], const StorageError());
    }
  }

  Future<(Message?, AppError?)> addMessage(Message message) async {
    try {
      final model = MessageModel.fromEntity(message);
      await _msgBox.put(model.id, model);
      // touch updatedAt on the parent conversation
      final conv = _convBox.get(message.conversationId);
      if (conv != null) {
        conv.updatedAt = message.createdAt;
        await conv.save();
      }
      return (model.toEntity(), null);
    } catch (_) {
      return (null, const StorageError());
    }
  }
}
