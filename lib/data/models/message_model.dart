import 'dart:convert' as dart_convert;
import 'package:hive/hive.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String conversationId;

  @HiveField(2)
  late int roleIndex; // 0 = user, 1 = assistant

  @HiveField(3)
  late String content;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  List<String>? attachmentsJson;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.roleIndex,
    required this.content,
    required this.createdAt,
    this.attachmentsJson,
  });

  factory MessageModel.fromEntity(Message m) {
    return MessageModel(
      id: m.id,
      conversationId: m.conversationId,
      roleIndex: m.role.index,
      content: m.content,
      createdAt: m.createdAt,
      attachmentsJson: m.attachments.map((a) {
        return '{"id":"${a.id}", "path":"${a.path.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}", "type":${a.type.index}, "mimeType":"${a.mimeType ?? ''}", "name":"${a.name?.replaceAll('\\', '\\\\').replaceAll('"', '\\"') ?? ''}"}';
      }).toList(),
    );
  }

  Message toEntity() {
    List<Attachment> atts = [];
    if (attachmentsJson != null) {
      for (var jsonStr in attachmentsJson!) {
        // Quick json parse without importing dart:convert if we don't want, wait we can just import dart:convert
        try {
          final Map<String, dynamic> map = dart_convert.jsonDecode(jsonStr);
          atts.add(Attachment(
            id: map['id'] as String,
            path: map['path'] as String,
            type: AttachmentType.values[map['type'] as int],
            mimeType: map['mimeType'] == '' ? null : map['mimeType'] as String,
            name: map['name'] == '' ? null : map['name'] as String,
          ));
        } catch (_) {}
      }
    }
    return Message(
      id: id,
      conversationId: conversationId,
      role: MessageRole.values[roleIndex],
      content: content,
      createdAt: createdAt,
      attachments: atts,
    );
  }
}
