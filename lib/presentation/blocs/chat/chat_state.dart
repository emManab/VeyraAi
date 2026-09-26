import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';
import '../../../core/error/app_error.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  final List<Message> messages;
  const ChatLoading({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class ChatReady extends ChatState {
  final List<Message> messages;
  const ChatReady({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class ChatSending extends ChatState {
  final List<Message> messages;
  const ChatSending({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final List<Message> messages;
  final AppError error;
  const ChatError({required this.messages, required this.error});
  @override
  List<Object?> get props => [messages, error];
}
