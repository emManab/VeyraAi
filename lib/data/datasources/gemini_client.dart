import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';
import '../../core/error/app_error.dart';

class GeminiClient {
  final http.Client _client;
  static const _timeout = Duration(seconds: 60);

  const GeminiClient(this._client);

  Future<(String?, AppError?)> chat({
    required String apiKey,
    required String model,
    required List<Message> history,
    required String userMessage,
    List<Attachment> attachments = const [],
  }) async {
    final contents = [
      for (final m in history)
        {
          'role': m.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': m.content},
            if (m.role == MessageRole.user && m.attachments.isNotEmpty)
              for (final a in m.attachments)
                if (a.type == AttachmentType.image)
                  {
                    'inlineData': {
                      'mimeType': a.mimeType ?? 'image/jpeg',
                      'data': base64Encode(File(a.path).readAsBytesSync())
                    }
                  }
          ],
        },
      {
        'role': 'user',
        'parts': [
          for (final a in attachments)
            if (a.type == AttachmentType.image)
              {
                'inlineData': {
                  'mimeType': a.mimeType ?? 'image/jpeg',
                  'data': base64Encode(File(a.path).readAsBytesSync())
                }
              },
          {'text': userMessage}
        ],
      },
    ];

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'contents': contents}),
          )
          .timeout(_timeout);

      return _parse(response);
    } on SocketException {
      return (null, const NetworkError());
    } on TimeoutException {
      return (null, const TimeoutError());
    } catch (_) {
      return (null, const UnknownError());
    }
  }

  (String?, AppError?) _parse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return (null, const AuthError());
    }
    if (response.statusCode == 429) return (null, const RateLimitError());
    if (response.statusCode != 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = json['error']?['message'] as String?;
        if (msg != null && msg.isNotEmpty) {
          if (msg.toLowerCase().contains('api key') || msg.contains('API_KEY')) {
            return (null, AuthError(msg));
          }
          return (null, InvalidResponseError(msg));
        }
      } catch (_) {}
      return (null, const InvalidResponseError());
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.isEmpty) return (null, const InvalidResponseError());
      return (text, null);
    } catch (_) {
      return (null, const InvalidResponseError());
    }
  }
}
