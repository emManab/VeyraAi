import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/chat/chat_event.dart';
import '../../presentation/blocs/chat/chat_state.dart';
import '../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../presentation/blocs/conversation/conversation_event.dart';
import '../../presentation/blocs/conversation/conversation_state.dart';
import '../../presentation/widgets/message_bubble.dart';
import '../../presentation/widgets/message_composer.dart';
import '../../presentation/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset > 200 && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      } else if (offset <= 200 && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
            String title = widget.conversation.title;
            if (state is ConversationListLoaded) {
              final conv = state.conversations.where((c) => c.id == widget.conversation.id).firstOrNull;
              if (conv != null) title = conv.title;
            }
            return Text(title, style: AppTypography.heading2);
          },
        ),
        actions: [
          BlocBuilder<ConversationBloc, ConversationState>(
            builder: (context, state) {
              String title = widget.conversation.title;
              if (state is ConversationListLoaded) {
                final conv = state.conversations.where((c) => c.id == widget.conversation.id).firstOrNull;
                if (conv != null) title = conv.title;
              }
              return IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  final ctrl = TextEditingController(text: title);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Edit title', style: AppTypography.titleLarge),
                      content: TextField(
                        controller: ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: AppTypography.buttonSmall),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              context.read<ConversationBloc>().add(
                                ConversationTitleUpdated(widget.conversation.id, ctrl.text.trim())
                              );
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text('Save', style: AppTypography.buttonSmall),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SizedBox(
            height: 4.0,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            ),
          ),
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () => context.read<ChatBloc>().add(const ChatErrorDismissed()),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final messages = switch (state) {
            ChatReady(messages: final m) => m,
            ChatSending(messages: final m) => m,
            ChatError(messages: final m) => m,
            ChatLoading(messages: final m) => m,
            _ => const <Message>[],
          };
          final isSending = state is ChatSending;
          final isLoading = state is ChatLoading && messages.isEmpty;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reversedMessages = messages.reversed.toList();

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? _EmptyChat(conversationId: widget.conversation.id)
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: reversedMessages.length + (isSending ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (isSending && index == 0) {
                                return const Align(
                                  alignment: Alignment.centerLeft,
                                  child: TypingIndicator(),
                                );
                              }
                              final messageIndex = isSending ? index - 1 : index;
                              final message = reversedMessages[messageIndex];
                              return MessageBubble(
                                key: ValueKey(message.id),
                                message: message,
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  MessageComposer(
                    isLoading: isSending,
                    onSend: (text, attachments) {
                      context.read<ChatBloc>().add(
                            ChatMessageSent(
                              conversationId: widget.conversation.id,
                              content: text,
                              attachments: attachments,
                            ),
                          );
                      _scrollToBottom();
                    },
                  ),
                ],
              ),
              if (_showScrollToBottom)
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: Semantics(
                    button: true,
                    label: 'Scroll to bottom',
                    child: FloatingActionButton.small(
                      tooltip: 'Scroll to bottom',
                      onPressed: _scrollToBottom,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(Icons.arrow_downward),
                    ).animate().fadeIn(duration: 200.ms).scale(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String conversationId;
  const _EmptyChat({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = [
      'Tell me a joke 😄',
      'Explain quantum computing 🔬',
      'Write a short poem 📝',
      'Help me with Flutter code 💻',
    ];

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.auto_awesome, size: 56, color: AppColors.primary),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('Start chatting', style: AppTypography.heading1).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text('Try one of these suggestions:', style: AppTypography.body).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: suggestions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  return ActionChip(
                    label: Text(text, style: AppTypography.chip),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    backgroundColor: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
                    onPressed: () {
                      context.read<ChatBloc>().add(
                            ChatMessageSent(
                              conversationId: conversationId,
                              content: text,
                            ),
                          );
                    },
                  ).animate().fadeIn(delay: (300 + idx * 80).ms).slideY(begin: 0.1, end: 0);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
