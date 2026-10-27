import '../../domain/entities/story_entity.dart';

class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.authorName,
    required super.authorAvatar,
    required super.mediaUrl,
    required super.caption,
    required super.timestamp,
    super.isViewed,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String,
      mediaUrl: json['mediaUrl'] as String,
      caption: json['caption'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isViewed: json['isViewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
      'isViewed': isViewed,
    };
  }
}
