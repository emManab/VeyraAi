import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final bool isTitleManuallySet;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    this.isTitleManuallySet = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({String? title, bool? isTitleManuallySet, DateTime? updatedAt}) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      isTitleManuallySet: isTitleManuallySet ?? this.isTitleManuallySet,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, isTitleManuallySet, createdAt, updatedAt];
}
