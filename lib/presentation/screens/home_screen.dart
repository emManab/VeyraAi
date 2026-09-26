import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../blocs/conversation/conversation_bloc.dart';
import '../blocs/conversation/conversation_event.dart';
import '../blocs/conversation/conversation_state.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import 'settings_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _startChat(String message) {
    if (message.trim().isEmpty) return;
    final msg = message.trim();
    _inputCtrl.clear();
    
    // Create conversation and navigate
    context.read<ConversationBloc>().add(ConversationCreated(
      'New Conversation',
      onSuccess: (conv) {
        if (mounted) {
          final uri = Uri(
            path: '/chats/chat/${conv.id}',
            queryParameters: {'initialMessage': msg},
          );
          context.push(uri.toString(), extra: conv);
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const SettingsDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _buildHeader(context, isDark),
              const SizedBox(height: AppSpacing.xl),
              _buildGreetingCard(context, isDark),
              const SizedBox(height: AppSpacing.xl),
              _buildInputBar(context, isDark),
              const SizedBox(height: AppSpacing.xxl),
              _buildSectionTitle('Featured Prompts', isDark),
              const SizedBox(height: AppSpacing.md),
              _buildFeaturedPrompts(context, isDark),
              const SizedBox(height: AppSpacing.xxl),
              _buildSectionTitle('Recent Conversations', isDark),
              const SizedBox(height: AppSpacing.md),
              _buildRecentConversations(context, isDark),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.titleLarge,
                    children: const [
                      TextSpan(text: 'Veyra AI '),
                      TextSpan(
                        text: 'Assistant',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Your intelligent companion',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.search_rounded),
              onPressed: () {
                // Navigate to chats tab (it has the search bar)
                context.go('/chats');
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                String initial = 'M';
                String? pic;
                if (state is SettingsReady) {
                  initial = state.profileName.isNotEmpty ? state.profileName[0].toUpperCase() : 'U';
                  pic = state.profilePicture.isNotEmpty ? state.profilePicture : null;
                }
                return GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    backgroundColor: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
                    radius: 18,
                    backgroundImage: pic != null ? FileImage(File(pic)) : null,
                    child: pic == null ? Text(
                      initial,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                    ) : null,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildGreetingCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: isDark 
            ? LinearGradient(
                colors: [AppColors.primaryDark, AppColors.surfaceDarkCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.greetingGradient,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOOD MORNING',
            style: AppTypography.greetingLabel.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              String name = 'User';
              if (state is SettingsReady) {
                name = state.profileName.isNotEmpty ? state.profileName : 'User';
              }
              return Text(
                name,
                style: AppTypography.greetingName.copyWith(
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.card,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: _startChat,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: AppColors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(Icons.mic, color: AppColors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: () => _startChat(_inputCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.sectionHeader.copyWith(
        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFeaturedPrompts(BuildContext context, bool isDark) {
    final prompts = [
      {
        'title': 'Write Code',
        'desc': 'Software engineering',
        'icon': Icons.code,
        'color': AppColors.categoryCode,
        'prompt': 'You are an expert software engineer. Help me write, debug, explain, and improve code. Provide production-quality solutions. How can I create a Flutter login screen?'
      },
      {
        'title': 'Summarize',
        'desc': 'Text or documents',
        'icon': Icons.article_outlined,
        'color': AppColors.categoryDoc,
        'prompt': 'Summarize the following content clearly. Extract the key points, important facts, and actionable information. Paste text to summarize below:'
      },
      {
        'title': 'UI Ideas',
        'desc': 'App design concepts',
        'icon': Icons.design_services,
        'color': AppColors.categoryIdea,
        'prompt': 'You are a senior product designer and mobile UI/UX engineer. Help me create modern, accessible, premium mobile interfaces. Design a premium AI chat home screen.'
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: prompts.asMap().entries.map((e) {
          final i = e.key;
          final prompt = e.value;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: InkWell(
              onTap: () => _startChat(prompt['prompt'] as String),
              borderRadius: AppRadius.cardRadius,
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkCard : AppColors.promptCardGray,
                  borderRadius: AppRadius.cardRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (prompt['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(prompt['icon'] as IconData, color: prompt['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(prompt['title'] as String, style: AppTypography.titleSmall),
                    const SizedBox(height: 4),
                    Text(prompt['desc'] as String, style: AppTypography.caption),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (400 + i * 100).ms).slideX(begin: 0.1, end: 0);
        }).toList(),
      ),
    );
  }

  Widget _buildRecentConversations(BuildContext context, bool isDark) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, state) {
        if (state is ConversationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        List<dynamic> convs = [];
        if (state is ConversationListLoaded) {
          convs = List.from(state.conversations);
        } else if (state is ConversationError) {
          convs = List.from(state.conversations);
        }
        
        if (convs.isEmpty) {
          return Text('No recent conversations.', style: AppTypography.body.copyWith(color: AppColors.textTertiary));
        }
        
        // Take top 3
        final recents = convs.take(3).toList();

        return Column(
          children: recents.asMap().entries.map((e) {
            final i = e.key;
            final conv = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  context.push('/chats/chat/${conv.id}', extra: conv);
                },
                borderRadius: AppRadius.cardRadius,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
                    borderRadius: AppRadius.cardRadius,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(conv.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(_formatTime(conv.updatedAt), style: AppTypography.caption),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (500 + i * 100).ms).slideY(begin: 0.1, end: 0),
            );
          }).toList(),
        );
      }
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return DateFormat.yMd().format(time);
  }
}
