import 'package:equatable/equatable.dart';
import '../../../domain/entities/conversation.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();
  @override
  List<Object?> get props => [];
}

class ConversationsLoaded extends ConversationEvent {
  const ConversationsLoaded();
}

class ConversationCreated extends ConversationEvent {
  final String title;
  final void Function(Conversation)? onSuccess;
  const ConversationCreated(this.title, {this.onSuccess});
  @override
  List<Object?> get props => [title, onSuccess];
}

class ConversationDeleted extends ConversationEvent {
  final String id;
  const ConversationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class ConversationSelected extends ConversationEvent {
  final Conversation conversation;
  const ConversationSelected(this.conversation);
  @override
  List<Object?> get props => [conversation];
}

class ConversationSelectionCleared extends ConversationEvent {
  const ConversationSelectionCleared();
}

class ConversationTitleUpdated extends ConversationEvent {
  final String id;
  final String title;
  const ConversationTitleUpdated(this.id, this.title);
  @override
  List<Object?> get props => [id, title];
}

