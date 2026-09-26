import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../presentation/blocs/conversation/conversation_event.dart';
import '../../presentation/blocs/conversation/conversation_state.dart';
import '../../presentation/widgets/conversation_tile.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  int _selectedFilter = 0;
  final _filters = ['All', 'Today', 'This Week', 'This Month', 'Pinned'];

  void _newConversation(BuildContext context) {
    final bloc = context.read<ConversationBloc>();
    showDialog<void>(
      context: context,
      builder: (ctx) => _NewConversationDialog(bloc: bloc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: AppSpacing.pagePadding,
              child: _buildHeader(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Text('Chats', style: AppTypography.heading1),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.pagePadding,
              child: _buildSearchBar(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFilters(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocConsumer<ConversationBloc, ConversationState>(
                listener: (context, state) {
                  if (state is ConversationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ConversationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final convs = switch (state) {
                    ConversationListLoaded(conversations: final c) => c,
                    ConversationError(conversations: final c) => c,
                    _ => null,
                  };

                  if (convs != null) {
                    if (convs.isEmpty) {
                      return _EmptyState(onNew: () => _newConversation(context));
                    }
                    
                    final selectedId = state is ConversationListLoaded ? state.selected?.id : null;
                    
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: convs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (ctx, i) {
                        return ConversationTile(
                          conversation: convs[i],
                          selected: selectedId == convs[i].id,
                          onTap: () => context.read<ConversationBloc>().add(ConversationSelected(convs[i])),
                          onDelete: () => context.read<ConversationBloc>().add(ConversationDeleted(convs[i].id)),
                        ).animate(delay: (i < 8 ? i * 40 : 0).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newConversation(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add),
        label: Text('New Chat', style: AppTypography.button),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.titleMedium,
                    children: const [
                      TextSpan(text: 'Veyra AI '),
                      TextSpan(
                        text: 'Assistant',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Text('Your intelligent companion', style: AppTypography.labelSmall),
              ],
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
          radius: 18,
          child: Text(
            'M',
            style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search your conversations...',
          hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_filters[index], style: isSelected ? AppTypography.chipSelected : AppTypography.chip),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = index);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.surfaceDarkCard 
                  : AppColors.surfaceWhite,
              side: isSelected ? BorderSide.none : BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ).animate().fadeIn(delay: (200 + index * 50).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _NewConversationDialog extends StatefulWidget {
  final ConversationBloc bloc;
  const _NewConversationDialog({required this.bloc});

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _ctrl.text.trim();
    if (title.isNotEmpty) {
      widget.bloc.add(ConversationCreated(
        title,
        onSuccess: (conv) {
          if (mounted) {
            context.push('/chats/chat/${conv.id}', extra: conv);
          }
        },
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New conversation', style: AppTypography.titleLarge),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Title...',
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTypography.buttonSmall.copyWith(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: _submit,
          child: Text('Create', style: AppTypography.buttonSmall),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Icon(Icons.auto_awesome, size: 72, color: Colors.white),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: AppTypography.heading2,
          ).animate().fadeIn().slideY(begin: 0.15, end: 0),
          const SizedBox(height: 10),
          Text(
            'Ask me anything or pick a topic',
            style: AppTypography.body,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onNew,
            icon: Icon(Icons.chat_bubble_outline),
            label: Text('New chat', style: AppTypography.button),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }
}
