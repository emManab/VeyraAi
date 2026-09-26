import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/conversation.dart';
import '../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../presentation/blocs/conversation/conversation_event.dart';
import '../../presentation/blocs/conversation/conversation_state.dart';
import '../../presentation/widgets/conversation_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: AppTypography.heading2),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          List<Conversation> convs = [];
          if (state is ConversationListLoaded) {
            convs = state.conversations;
          } else if (state is ConversationError) {
            convs = state.conversations;
          }

          if (convs.isNotEmpty) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final weekAgo = today.subtract(const Duration(days: 7));

            final List<Conversation> todayConvs = [];
            final List<Conversation> yesterdayConvs = [];
            final List<Conversation> weekConvs = [];
            final List<Conversation> olderConvs = [];

            for (var c in convs) {
              final d = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
              if (!d.isBefore(today)) {
                todayConvs.add(c);
              } else if (!d.isBefore(yesterday)) {
                yesterdayConvs.add(c);
              } else if (!d.isBefore(weekAgo)) {
                weekConvs.add(c);
              } else {
                olderConvs.add(c);
              }
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              children: [
                _buildTimeGroup('Today', context, todayConvs),
                _buildTimeGroup('Yesterday', context, yesterdayConvs),
                _buildTimeGroup('Previous 7 Days', context, weekConvs),
                _buildTimeGroup('Older', context, olderConvs),
              ],
            );
          }
          
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.md),
                Text('No history yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ).animate().fadeIn(),
          );
        },
      ),
    );
  }

  Widget _buildTimeGroup(String title, BuildContext context, List<Conversation> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
        ),
        ...items.map((conv) => ConversationTile(
          conversation: conv,
          selected: false,
          onTap: () {
            context.push('/chats/chat/${conv.id}', extra: conv);
          },
          onDelete: () => context.read<ConversationBloc>().add(ConversationDeleted(conv.id)),
        )),
        const SizedBox(height: AppSpacing.md),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
