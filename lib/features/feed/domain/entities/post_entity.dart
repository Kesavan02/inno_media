import 'package:equatable/equatable.dart';
import 'comment_entity.dart';

class PostEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String location;
  final String caption;
  final List<String> tags;
  final String imageUrl;
  final int likesCount;
  final bool isLiked;
  final bool isBookmarked;
  final List<CommentEntity> comments;
  final DateTime createdAt;

  const PostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.location,
    required this.caption,
    required this.tags,
    required this.imageUrl,
    required this.likesCount,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.comments,
    required this.createdAt,
  });

  PostEntity copyWith({
    int? likesCount,
    bool? isLiked,
    bool? isBookmarked,
    List<CommentEntity>? comments,
  }) {
    return PostEntity(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      location: location,
      caption: caption,
      tags: tags,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorUsername,
        authorAvatar,
        location,
        caption,
        tags,
        imageUrl,
        likesCount,
        isLiked,
        isBookmarked,
        comments,
        createdAt,
      ];
}
