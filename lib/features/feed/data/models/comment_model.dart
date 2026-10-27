import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.authorName,
    required super.authorAvatar,
    required super.text,
    required super.timestamp,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['timestamp'] ?? json['createdAt'] ?? json['createdAtTimestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return CommentModel(
      id: json['id'] as String? ?? 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorName: json['authorName'] as String? ?? 'User',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

