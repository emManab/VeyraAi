import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/message.dart';
import '../../core/error/app_error.dart';

class FreeAIClient {
  final http.Client _client;
  static const _timeout = Duration(seconds: 45);

  const FreeAIClient(this._client);

  Future<(String?, AppError?)> chat({
    required List<Message> history,
    required String userMessage,
  }) async {
    final messages = [
      for (final m in history)
        {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        },
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _client
          .post(
            Uri.parse('https://text.pollinations.ai/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': messages,
              'model': 'openai',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        return (response.body.trim(), null);
      }
      return (
        null,
        const InvalidResponseError('Free AI server returned an empty response.')
      );
    } on SocketException {
      return (null, const NetworkError('Veyra Free is temporarily unavailable. Please try again.'));
    } on TimeoutException {
      return (null, const TimeoutError('Veyra Free took too long to respond. Please try again.'));
    } catch (_) {
      return (null, const UnknownError('Veyra Free is temporarily unavailable. Please try again.'));
    }
  }
}
