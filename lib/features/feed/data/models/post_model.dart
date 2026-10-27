import '../../domain/entities/post_entity.dart';
import 'comment_model.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    required super.authorUsername,
    required super.authorAvatar,
    required super.location,
    required super.caption,
    required super.tags,
    required super.imageUrl,
    required super.likesCount,
    super.isLiked,
    super.isBookmarked,
    required super.comments,
    required super.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorUsername: json['authorUsername'] as String,
      authorAvatar: json['authorAvatar'] as String,
      location: json['location'] as String,
      caption: json['caption'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['imageUrl'] as String,
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorAvatar': authorAvatar,
      'location': location,
      'caption': caption,
      'tags': tags,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'comments': comments.map((c) => (c as CommentModel).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
