import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_chat_assistant/domain/entities/ai_provider_config.dart';
import 'package:ai_chat_assistant/domain/entities/message.dart';
import 'package:ai_chat_assistant/domain/usecases/usecases.dart';
import 'package:ai_chat_assistant/core/error/app_error.dart';
import 'package:ai_chat_assistant/presentation/blocs/chat/chat_bloc.dart';
import 'package:ai_chat_assistant/presentation/blocs/chat/chat_event.dart';
import 'package:ai_chat_assistant/presentation/blocs/chat/chat_state.dart';
import 'package:ai_chat_assistant/presentation/blocs/conversation/conversation_bloc.dart';

class MockGetMessages extends Mock implements GetMessages {}
class MockSendChatMessage extends Mock implements SendChatMessage {}
class MockGetProviderConfig extends Mock implements GetProviderConfig {}
class MockGetApiKey extends Mock implements GetApiKey {}
class MockConversationBloc extends Mock implements ConversationBloc {}

void main() {
  late MockGetMessages mockGetMessages;
  late MockSendChatMessage mockSendChatMessage;
  late MockGetProviderConfig mockGetProviderConfig;
  late MockGetApiKey mockGetApiKey;
  late MockConversationBloc mockConversationBloc;

  setUpAll(() {
    registerFallbackValue(AIProviderConfig.defaultConfig);
    registerFallbackValue(AIProvider.openai);
  });

  setUp(() {
    mockGetMessages = MockGetMessages();
    mockSendChatMessage = MockSendChatMessage();
    mockGetProviderConfig = MockGetProviderConfig();
    mockGetApiKey = MockGetApiKey();
    mockConversationBloc = MockConversationBloc();
  });

  ChatBloc buildBloc() => ChatBloc(
        getMessages: mockGetMessages,
        sendChatMessage: mockSendChatMessage,
        getProviderConfig: mockGetProviderConfig,
        getApiKey: mockGetApiKey,
        conversationBloc: mockConversationBloc,
      );

  group('ChatBloc', () {
    final tMessages = [
      Message(
        id: 'm1',
        conversationId: 'c1',
        role: MessageRole.user,
        content: 'Hi',
        createdAt: DateTime(2026, 1, 1),
      ),
      Message(
        id: 'm2',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: 'Hello!',
        createdAt: DateTime(2026, 1, 1, 0, 1),
      ),
    ];

    test('initial state is ChatInitial', () {
      expect(buildBloc().state, const ChatInitial());
    });

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatReady] when ChatLoaded succeeds',
      build: () {
        when(() => mockGetMessages('c1')).thenAnswer((_) async => (tMessages, null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatLoaded('c1')),
      expect: () => [
        const ChatLoading(messages: []),
        ChatReady(messages: tMessages),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatError] when ChatLoaded fails',
      build: () {
        when(() => mockGetMessages('c1')).thenAnswer((_) async => (<Message>[], const StorageError()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatLoaded('c1')),
      expect: () => [
        const ChatLoading(messages: []),
        const ChatError(messages: [], error: StorageError()),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'proceeds with empty apiKey to allow Free AI fallback when API key is empty',
      build: () {
        when(() => mockGetProviderConfig())
            .thenAnswer((_) async => (AIProviderConfig.defaultConfig, null));
        when(() => mockGetApiKey(any())).thenAnswer((_) async => (null, null));
        when(() => mockSendChatMessage(
              conversationId: any(named: 'conversationId'),
              history: any(named: 'history'),
              userContent: any(named: 'userContent'),
              config: any(named: 'config'),
              apiKey: any(named: 'apiKey'),
            )).thenAnswer((_) async => (
              Message(
                id: 'm_reply',
                conversationId: 'c1',
                role: MessageRole.assistant,
                content: 'Free AI Response',
                createdAt: DateTime.now(),
              ),
              null
            ));
        when(() => mockGetMessages('c1')).thenAnswer((_) async => (tMessages, null));
        return buildBloc();
      },
      seed: () => const ChatReady(messages: []),
      act: (bloc) => bloc.add(const ChatMessageSent(conversationId: 'c1', content: 'Hello')),
      expect: () => [
        isA<ChatSending>(),
        isA<ChatReady>(),
      ],
      verify: (_) {
        verify(() => mockSendChatMessage(
              conversationId: 'c1',
              history: [],
              userContent: 'Hello',
              config: AIProviderConfig.defaultConfig,
              apiKey: '',
            )).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatSending, ChatReady] when sending succeeds',
      build: () {
        when(() => mockGetProviderConfig())
            .thenAnswer((_) async => (AIProviderConfig.defaultConfig, null));
        when(() => mockGetApiKey(any())).thenAnswer((_) async => ('valid-key', null));
        when(() => mockSendChatMessage(
              conversationId: any(named: 'conversationId'),
              history: any(named: 'history'),
              userContent: any(named: 'userContent'),
              config: any(named: 'config'),
              apiKey: any(named: 'apiKey'),
            )).thenAnswer((_) async => (
              Message(
                id: 'm_reply',
                conversationId: 'c1',
                role: MessageRole.assistant,
                content: 'AI Response',
                createdAt: DateTime.now(),
              ),
              null
            ));
        when(() => mockGetMessages('c1')).thenAnswer((_) async => (tMessages, null));
        return buildBloc();
      },
      seed: () => const ChatReady(messages: []),
      act: (bloc) => bloc.add(const ChatMessageSent(conversationId: 'c1', content: 'Hello')),
      expect: () => [
        isA<ChatSending>(),
        isA<ChatReady>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatReady] when ChatErrorDismissed is added',
      build: () => buildBloc(),
      seed: () => const ChatError(messages: [], error: NetworkError()),
      act: (bloc) => bloc.add(const ChatErrorDismissed()),
      expect: () => [
        const ChatReady(messages: []),
      ],
    );
  });
}
