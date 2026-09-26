import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';
import '../../core/error/app_error.dart';

class OpenAIClient {
  final http.Client _client;
  static const _timeout = Duration(seconds: 60);

  const OpenAIClient(this._client);

  Future<(String?, AppError?)> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Message> history,
    required String userMessage,
    List<Attachment> attachments = const [],
  }) async {
    dynamic buildContent(String text, List<Attachment> atts) {
      final images = atts.where((a) => a.type == AttachmentType.image).toList();
      if (images.isEmpty) return text;
      
      return [
        {'type': 'text', 'text': text},
        for (final a in images)
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${a.mimeType ?? "image/jpeg"};base64,${base64Encode(File(a.path).readAsBytesSync())}'
            }
          }
      ];
    }

    final messages = [
      for (final m in history)
        {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.role == MessageRole.user ? buildContent(m.content, m.attachments) : m.content
        },
      {'role': 'user', 'content': buildContent(userMessage, attachments)},
    ];

    final uri = Uri.parse('$baseUrl/chat/completions');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({'model': model, 'messages': messages}),
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
    if (response.statusCode == 401) {
      return (null, const AuthError());
    }
    if (response.statusCode == 429) return (null, const RateLimitError());
    if (response.statusCode != 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = json['error']?['message'] as String?;
        if (msg != null && msg.isNotEmpty) {
          if (msg.toLowerCase().contains('api key') || msg.contains('incorrect API key')) {
            return (null, AuthError(msg));
          }
          return (null, InvalidResponseError(msg));
        }
      } catch (_) {}
      return (null, const InvalidResponseError());
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) return (null, const InvalidResponseError());
      return (content, null);
    } catch (_) {
      return (null, const InvalidResponseError());
    }
  }
}
