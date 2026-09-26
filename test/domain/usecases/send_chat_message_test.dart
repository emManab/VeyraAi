import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_chat_assistant/domain/entities/ai_provider_config.dart';
import 'package:ai_chat_assistant/domain/entities/message.dart';
import 'package:ai_chat_assistant/domain/repositories/ai_repository.dart';
import 'package:ai_chat_assistant/domain/repositories/conversation_repository.dart';
import 'package:ai_chat_assistant/domain/usecases/usecases.dart';
import 'package:ai_chat_assistant/core/error/app_error.dart';

class MockAIRepository extends Mock implements AIRepository {}
class MockConversationRepository extends Mock implements ConversationRepository {}

void main() {
  late MockAIRepository mockAiRepo;
  late MockConversationRepository mockConvRepo;
  late SendChatMessage usecase;

  setUpAll(() {
    registerFallbackValue(
      Message(
        id: 'fallback',
        conversationId: 'c1',
        role: MessageRole.user,
        content: 'fallback',
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(AIProviderConfig.defaultConfig);
  });

  setUp(() {
    mockAiRepo = MockAIRepository();
    mockConvRepo = MockConversationRepository();
    usecase = SendChatMessage(mockAiRepo, mockConvRepo);
  });

  test('sends message successfully and saves both user and assistant messages', () async {
    when(() => mockConvRepo.addMessage(any()))
        .thenAnswer((invocation) async {
      final msg = invocation.positionalArguments.first as Message;
      return (msg, null);
    });

    when(() => mockConvRepo.updateConversationTitle(any(), any()))
        .thenAnswer((_) async => null);

    when(() => mockAiRepo.sendMessage(
          history: any(named: 'history'),
          userMessage: any(named: 'userMessage'),
          config: any(named: 'config'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ('Hello human', null));

    final (result, error) = await usecase(
      conversationId: 'c1',
      history: [],
      userContent: 'Hello AI',
      config: AIProviderConfig.defaultConfig,
      apiKey: 'test-key',
    );

    expect(error, isNull);
    expect(result, isNotNull);
    expect(result!.content, 'Hello human');
    expect(result.role, MessageRole.assistant);

    // Verify AI received clean history without appending duplicate user message
    verify(() => mockAiRepo.sendMessage(
          history: [],
          userMessage: 'Hello AI',
          config: AIProviderConfig.defaultConfig,
          apiKey: 'test-key',
        )).called(1);

    // Verify two messages were saved: user and assistant
    verify(() => mockConvRepo.addMessage(any())).called(2);
  });

  test('returns NetworkError when AI repository fails', () async {
    when(() => mockConvRepo.addMessage(any()))
        .thenAnswer((invocation) async {
      final msg = invocation.positionalArguments.first as Message;
      return (msg, null);
    });

    when(() => mockConvRepo.updateConversationTitle(any(), any()))
        .thenAnswer((_) async => null);

    when(() => mockAiRepo.sendMessage(
          history: any(named: 'history'),
          userMessage: any(named: 'userMessage'),
          config: any(named: 'config'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => (null, const NetworkError()));

    final (result, error) = await usecase(
      conversationId: 'c1',
      history: [],
      userContent: 'Hello AI',
      config: AIProviderConfig.defaultConfig,
      apiKey: 'test-key',
    );

    expect(result, isNull);
    expect(error, isA<NetworkError>());
  });
}
