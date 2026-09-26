import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_chat_assistant/domain/entities/conversation.dart';
import 'package:ai_chat_assistant/domain/usecases/usecases.dart';
import 'package:ai_chat_assistant/core/error/app_error.dart';
import 'package:ai_chat_assistant/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:ai_chat_assistant/presentation/blocs/conversation/conversation_event.dart';
import 'package:ai_chat_assistant/presentation/blocs/conversation/conversation_state.dart';

class MockGetConversations extends Mock implements GetConversations {}
class MockCreateConversation extends Mock implements CreateConversation {}
class MockDeleteConversation extends Mock implements DeleteConversation {}

class MockUpdateConversationTitle extends Mock implements UpdateConversationTitle {}

void main() {
  late MockGetConversations mockGetConversations;
  late MockCreateConversation mockCreateConversation;
  late MockDeleteConversation mockDeleteConversation;
  late MockUpdateConversationTitle mockUpdateConversationTitle;

  setUp(() {
    mockGetConversations = MockGetConversations();
    mockCreateConversation = MockCreateConversation();
    mockDeleteConversation = MockDeleteConversation();
    mockUpdateConversationTitle = MockUpdateConversationTitle();
  });

  ConversationBloc buildBloc() => ConversationBloc(
        getConversations: mockGetConversations,
        createConversation: mockCreateConversation,
        deleteConversation: mockDeleteConversation,
        updateConversationTitle: mockUpdateConversationTitle,
      );

  group('ConversationBloc', () {
    final tConv1 = Conversation(
      id: 'c1',
      title: 'First Chat',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final tConv2 = Conversation(
      id: 'c2',
      title: 'Second Chat',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    );

    test('initial state is ConversationInitial', () {
      expect(buildBloc().state, const ConversationInitial());
    });

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationLoading, ConversationListLoaded] when ConversationsLoaded succeeds',
      build: () {
        when(() => mockGetConversations()).thenAnswer((_) async => ([tConv1, tConv2], null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ConversationsLoaded()),
      expect: () => [
        const ConversationLoading(),
        ConversationListLoaded(conversations: [tConv1, tConv2]),
      ],
    );

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationListLoaded] with prepended item when ConversationCreated succeeds',
      build: () {
        when(() => mockCreateConversation('New Chat'))
            .thenAnswer((_) async => (tConv2, null));
        return buildBloc();
      },
      seed: () => ConversationListLoaded(conversations: [tConv1]),
      act: (bloc) => bloc.add(const ConversationCreated('New Chat')),
      expect: () => [
        ConversationListLoaded(conversations: [tConv2, tConv1]),
      ],
    );

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationListLoaded] without item when ConversationDeleted succeeds',
      build: () {
        when(() => mockDeleteConversation('c1')).thenAnswer((_) async => null);
        return buildBloc();
      },
      seed: () => ConversationListLoaded(conversations: [tConv1, tConv2]),
      act: (bloc) => bloc.add(const ConversationDeleted('c1')),
      expect: () => [
        ConversationListLoaded(conversations: [tConv2]),
      ],
    );

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationError] preserving current list when creation fails',
      build: () {
        when(() => mockCreateConversation('Fail'))
            .thenAnswer((_) async => (null, const StorageError()));
        return buildBloc();
      },
      seed: () => ConversationListLoaded(conversations: [tConv1]),
      act: (bloc) => bloc.add(const ConversationCreated('Fail')),
      expect: () => [
        ConversationError(conversations: [tConv1], error: const StorageError()),
      ],
    );

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationListLoaded] with null selected when ConversationSelectionCleared is added',
      build: () => buildBloc(),
      seed: () => ConversationListLoaded(conversations: [tConv1], selected: tConv1),
      act: (bloc) => bloc.add(const ConversationSelectionCleared()),
      expect: () => [
        ConversationListLoaded(conversations: [tConv1], selected: null),
      ],
    );
  });
}
