import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String text;
  final DateTime timestamp;

  const CommentEntity({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, authorName, authorAvatar, text, timestamp];
}
