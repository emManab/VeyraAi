import 'package:equatable/equatable.dart';

enum AttachmentType { image, document }

class Attachment extends Equatable {
  final String id;
  final String path;
  final AttachmentType type;
  final String? mimeType;
  final String? name;

  const Attachment({
    required this.id,
    required this.path,
    required this.type,
    this.mimeType,
    this.name,
  });

  @override
  List<Object?> get props => [id, path, type, mimeType, name];
}
