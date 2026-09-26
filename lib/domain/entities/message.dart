import 'package:equatable/equatable.dart';
import 'attachment.dart';

enum MessageRole { user, assistant }

class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final List<Attachment> attachments;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
  });

  @override
  List<Object?> get props => [id, conversationId, role, content, createdAt, attachments];
}
