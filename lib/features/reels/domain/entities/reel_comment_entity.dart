import 'package:equatable/equatable.dart';

class ReelCommentEntity extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String text;
  final DateTime createdAt;

  const ReelCommentEntity({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, authorName, authorAvatar, text, createdAt];
}
