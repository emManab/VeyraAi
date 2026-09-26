import 'package:equatable/equatable.dart';
import '../../../domain/entities/attachment.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatLoaded extends ChatEvent {
  final String conversationId;
  const ChatLoaded(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class ChatMessageSent extends ChatEvent {
  final String conversationId;
  final String content;
  final List<Attachment> attachments;
  const ChatMessageSent({required this.conversationId, required this.content, this.attachments = const []});
  @override
  List<Object?> get props => [conversationId, content, attachments];
}

class ChatErrorDismissed extends ChatEvent {
  const ChatErrorDismissed();
}
