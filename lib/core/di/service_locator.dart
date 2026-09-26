import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.g.dart';
import '../../data/models/message_model.g.dart';
import '../../data/datasources/hive_conversation_source.dart';
import '../../data/datasources/hive_settings_source.dart';
import '../../data/datasources/openai_client.dart';
import '../../data/datasources/gemini_client.dart';
import '../../data/datasources/free_ai_client.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  Hive.registerAdapter(ConversationModelAdapter());
  Hive.registerAdapter(MessageModelAdapter());

  await Hive.openBox<ConversationModel>('conversations');
  await Hive.openBox<MessageModel>('messages');
  await Hive.openBox('app_settings');

  // Infrastructure
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Data sources
  sl.registerLazySingleton<HiveConversationSource>(
    () => HiveConversationSource(),
  );
  sl.registerLazySingleton<HiveSettingsSource>(
    () => HiveSettingsSource(sl()),
  );
  sl.registerLazySingleton<OpenAIClient>(() => OpenAIClient(sl<http.Client>()));
  sl.registerLazySingleton<GeminiClient>(() => GeminiClient(sl<http.Client>()));
  sl.registerLazySingleton<FreeAIClient>(() => FreeAIClient(sl<http.Client>()));

  // Repositories
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(sl<OpenAIClient>(), sl<GeminiClient>(), sl<FreeAIClient>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => CreateConversation(sl()));
  sl.registerLazySingleton(() => DeleteConversation(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendChatMessage(sl(), sl()));
  sl.registerLazySingleton(() => UpdateConversationTitle(sl()));
  sl.registerLazySingleton(() => GetProviderConfig(sl()));
  sl.registerLazySingleton(() => SaveProviderConfig(sl()));
  sl.registerLazySingleton(() => GetApiKey(sl()));
  sl.registerLazySingleton(() => SaveApiKey(sl()));

  sl.registerLazySingleton(() => GetAppAppearance(sl()));
  sl.registerLazySingleton(() => SaveAppAppearance(sl()));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => SaveProfile(sl()));

  // Blocs
  sl.registerLazySingleton(() => ConversationBloc(
        getConversations: sl(),
        createConversation: sl(),
        deleteConversation: sl(),
        updateConversationTitle: sl(),
      ));
  sl.registerFactory(() => ChatBloc(
        getMessages: sl(),
        sendChatMessage: sl(),
        getProviderConfig: sl(),
        getApiKey: sl(),
        conversationBloc: sl(),
      ));
  sl.registerLazySingleton(() => SettingsBloc(
        getProviderConfig: sl(),
        saveProviderConfig: sl(),
        saveApiKey: sl(),
        getAppAppearance: sl(),
        saveAppAppearance: sl(),
        getProfile: sl(),
        saveProfile: sl(),
      ));
}
