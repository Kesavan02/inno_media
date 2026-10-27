import '../../domain/entities/reel_entity.dart';
import 'reel_comment_model.dart';

class ReelModel extends ReelEntity {
  const ReelModel({
    required super.id,
    required super.authorName,
    required super.authorUsername,
    required super.authorAvatar,
    required super.videoAssetPath,
    required super.caption,
    required super.musicTrack,
    required super.likesCount,
    super.isLiked,
    super.sharesCount,
    required super.comments,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorUsername: json['authorUsername'] as String,
      authorAvatar: json['authorAvatar'] as String,
      videoAssetPath: json['videoAssetPath'] as String,
      caption: json['caption'] as String,
      musicTrack: json['musicTrack'] as String,
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      sharesCount: json['sharesCount'] as int? ?? 0,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => ReelCommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorAvatar': authorAvatar,
      'videoAssetPath': videoAssetPath,
      'caption': caption,
      'musicTrack': musicTrack,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'sharesCount': sharesCount,
      'comments': comments.map((c) {
        if (c is ReelCommentModel) return c.toJson();
        return {
          'id': c.id,
          'authorName': c.authorName,
          'authorAvatar': c.authorAvatar,
          'text': c.text,
          'createdAt': c.createdAt.toIso8601String(),
        };
      }).toList(),
    };
  }
}
