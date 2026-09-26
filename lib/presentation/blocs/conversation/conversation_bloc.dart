import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../domain/entities/conversation.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversations _getConversations;
  final CreateConversation _createConversation;
  final DeleteConversation _deleteConversation;
  final UpdateConversationTitle _updateConversationTitle;

  ConversationBloc({
    required GetConversations getConversations,
    required CreateConversation createConversation,
    required DeleteConversation deleteConversation,
    required UpdateConversationTitle updateConversationTitle,
  })  : _getConversations = getConversations,
        _createConversation = createConversation,
        _deleteConversation = deleteConversation,
        _updateConversationTitle = updateConversationTitle,
        super(const ConversationInitial()) {
    on<ConversationsLoaded>(_onLoaded);
    on<ConversationCreated>(_onCreated);
    on<ConversationDeleted>(_onDeleted);
    on<ConversationSelected>(_onSelected);
    on<ConversationSelectionCleared>(_onSelectionCleared);
    on<ConversationTitleUpdated>(_onTitleUpdated);
  }

  void _onSelectionCleared(
      ConversationSelectionCleared event, Emitter<ConversationState> emit) {
    final current = _currentList();
    emit(ConversationListLoaded(conversations: current, selected: null));
  }

  Future<void> _onLoaded(
      ConversationsLoaded event, Emitter<ConversationState> emit) async {
    emit(const ConversationLoading());
    final (convs, err) = await _getConversations();
    if (err != null) {
      emit(ConversationError(error: err));
    } else {
      emit(ConversationListLoaded(conversations: convs));
    }
  }

  Future<void> _onCreated(
      ConversationCreated event, Emitter<ConversationState> emit) async {
    final current = _currentList();
    final (conv, err) = await _createConversation(event.title);
    if (err != null) {
      emit(ConversationError(conversations: current, error: err));
    } else {
      final updated = [conv!, ...current];
      emit(ConversationListLoaded(conversations: updated));
      event.onSuccess?.call(conv);
    }
  }

  Future<void> _onDeleted(
      ConversationDeleted event, Emitter<ConversationState> emit) async {
    final current = _currentList();
    final err = await _deleteConversation(event.id);
    if (err != null) {
      emit(ConversationError(conversations: current, error: err));
    } else {
      final updated = current.where((c) => c.id != event.id).toList();
      final selected = state is ConversationListLoaded
          ? (state as ConversationListLoaded).selected
          : null;
      emit(ConversationListLoaded(
        conversations: updated,
        selected: selected?.id == event.id ? null : selected,
      ));
    }
  }

  void _onSelected(
      ConversationSelected event, Emitter<ConversationState> emit) {
    final current = _currentList();
    emit(ConversationListLoaded(
        conversations: current, selected: event.conversation));
  }

  Future<void> _onTitleUpdated(
      ConversationTitleUpdated event, Emitter<ConversationState> emit) async {
    final current = _currentList();
    final err = await _updateConversationTitle(event.id, event.title, isManuallySet: true);
    if (err != null) {
      emit(ConversationError(conversations: current, error: err));
    } else {
      final updated = current.map((c) {
        if (c.id == event.id) {
          return c.copyWith(title: event.title, isTitleManuallySet: true);
        }
        return c;
      }).toList();
      final selected = state is ConversationListLoaded
          ? (state as ConversationListLoaded).selected
          : null;
      emit(ConversationListLoaded(
        conversations: updated,
        selected: selected?.id == event.id ? updated.firstWhere((c) => c.id == event.id) : selected,
      ));
    }
  }

  List<Conversation> _currentList() {
    if (state is ConversationListLoaded) {
      return (state as ConversationListLoaded).conversations;
    }
    if (state is ConversationError) {
      return (state as ConversationError).conversations;
    }
    return [];
  }
}
