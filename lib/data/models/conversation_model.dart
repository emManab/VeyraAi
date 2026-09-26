import 'package:hive/hive.dart';
import '../../domain/entities/conversation.dart';

@HiveType(typeId: 0)
class ConversationModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(4, defaultValue: false)
  late bool isTitleManuallySet;

  ConversationModel({
    required this.id,
    required this.title,
    this.isTitleManuallySet = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
        id: c.id,
        title: c.title,
        isTitleManuallySet: c.isTitleManuallySet,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  Conversation toEntity() => Conversation(
        id: id,
        title: title,
        isTitleManuallySet: isTitleManuallySet,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
