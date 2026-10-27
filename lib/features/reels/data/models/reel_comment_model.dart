import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reel_comment_entity.dart';

class ReelCommentModel extends ReelCommentEntity {
  const ReelCommentModel({
    required super.id,
    required super.authorName,
    required super.authorAvatar,
    required super.text,
    required super.createdAt,
  });

  factory ReelCommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['createdAt'] ?? json['createdAtTimestamp'] ?? json['timestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return ReelCommentModel(
      id: json['id'] as String? ?? 'rc_${DateTime.now().millisecondsSinceEpoch}',
      authorName: json['authorName'] as String? ?? 'User',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: parsedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

