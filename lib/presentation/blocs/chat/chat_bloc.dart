import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/ai_provider_config.dart';
import 'chat_event.dart';
import 'chat_state.dart';

import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages _getMessages;
  final SendChatMessage _sendMessage;
  final GetProviderConfig _getConfig;
  final GetApiKey _getApiKey;
  final ConversationBloc _conversationBloc;

  ChatBloc({
    required GetMessages getMessages,
    required SendChatMessage sendChatMessage,
    required GetProviderConfig getProviderConfig,
    required GetApiKey getApiKey,
    required ConversationBloc conversationBloc,
  })  : _getMessages = getMessages,
        _sendMessage = sendChatMessage,
        _getConfig = getProviderConfig,
        _getApiKey = getApiKey,
        _conversationBloc = conversationBloc,
        super(const ChatInitial()) {
    on<ChatLoaded>(_onLoaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatErrorDismissed>(_onErrorDismissed);
  }

  Future<void> _onLoaded(ChatLoaded event, Emitter<ChatState> emit) async {
    emit(const ChatLoading(messages: []));
    final (msgs, err) = await _getMessages(event.conversationId);
    if (err != null) {
      emit(ChatError(messages: const [], error: err));
    } else {
      emit(ChatReady(messages: msgs));
    }
  }

  Future<void> _onMessageSent(
      ChatMessageSent event, Emitter<ChatState> emit) async {
    // Duplicate-send guard
    if (state is ChatSending) return;

    final trimmed = event.content.trim();
    if (trimmed.isEmpty) return;

    final current = _currentMessages();
    final now = DateTime.now();
    final optimisticMsg = Message(
      id: '${event.conversationId}_u_${now.millisecondsSinceEpoch}',
      conversationId: event.conversationId,
      role: MessageRole.user,
      content: trimmed,
      createdAt: now,
      attachments: event.attachments,
    );
    final optimisticList = [...current, optimisticMsg];
    emit(ChatSending(messages: optimisticList));

    final (config, configErr) = await _getConfig();
    if (configErr != null) {
      emit(ChatError(messages: optimisticList, error: configErr));
      return;
    }

    final effectiveConfig = config ?? AIProviderConfig.defaultConfig;
    final (apiKey, _) = await _getApiKey(effectiveConfig.provider);

    final (_, sendErr) = await _sendMessage(
      conversationId: event.conversationId,
      history: current,
      userContent: trimmed,
      config: effectiveConfig,
      apiKey: apiKey?.trim() ?? '',
      attachments: event.attachments,
    );

    if (sendErr != null) {
      emit(ChatError(messages: optimisticList, error: sendErr));
    } else {
      _conversationBloc.add(const ConversationsLoaded());
      final (refreshed, fetchErr) = await _getMessages(event.conversationId);
      emit(ChatReady(messages: fetchErr != null ? optimisticList : refreshed));
    }
  }

  void _onErrorDismissed(ChatErrorDismissed event, Emitter<ChatState> emit) {
    final msgs =
        state is ChatError ? (state as ChatError).messages : <Message>[];
    emit(ChatReady(messages: msgs));
  }

  List<Message> _currentMessages() {
    return switch (state) {
      ChatReady(messages: final m) => m,
      ChatSending(messages: final m) => m,
      ChatError(messages: final m) => m,
      ChatLoading(messages: final m) => m,
      _ => [],
    };
  }
}
