import 'package:equatable/equatable.dart';
import '../../../domain/entities/conversation.dart';
import '../../../core/error/app_error.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();
  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationListLoaded extends ConversationState {
  final List<Conversation> conversations;
  final Conversation? selected;
  const ConversationListLoaded({required this.conversations, this.selected});
  @override
  List<Object?> get props => [conversations, selected];
}

class ConversationError extends ConversationState {
  final List<Conversation> conversations;
  final AppError error;
  const ConversationError({this.conversations = const [], required this.error});
  @override
  List<Object?> get props => [conversations, error];
}
