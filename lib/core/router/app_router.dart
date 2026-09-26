import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/conversation.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/chat/chat_event.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/conversation_list_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/main_scaffold.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/privacy_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final isGoingToSplash = state.matchedLocation == '/splash';
    if (isGoingToSplash) return null;

    final box = Hive.box('app_settings');
    final hasOnboarded = box.get('hasOnboarded', defaultValue: false) as bool;
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';
    
    if (!hasOnboarded && !isGoingToOnboarding) {
      return '/onboarding';
    } else if (hasOnboarded && isGoingToOnboarding) {
      return '/';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        // Using existing singleton provided at the root
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: Chats
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ConversationListScreen(),
              routes: [
                GoRoute(
                  path: 'chat/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    final initialMessage = state.uri.queryParameters['initialMessage'];
                    
                    final conv = (state.extra is Conversation)
                        ? state.extra as Conversation
                        : Conversation(
                            id: id,
                            title: 'New Conversation',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: BlocProvider<ChatBloc>(
                        create: (_) {
                          final bloc = sl<ChatBloc>()..add(ChatLoaded(conv.id));
                          if (initialMessage != null && initialMessage.isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (!bloc.isClosed) {
                                bloc.add(ChatMessageSent(
                                  conversationId: conv.id,
                                  content: initialMessage,
                                ));
                              }
                            });
                          }
                          return bloc;
                        },
                        child: ChatScreen(conversation: conv),
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOut))
                              .animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 2: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
