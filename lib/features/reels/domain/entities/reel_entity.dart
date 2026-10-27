import 'package:equatable/equatable.dart';
import 'reel_comment_entity.dart';

class ReelEntity extends Equatable {
  final String id;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String videoAssetPath;
  final String caption;
  final String musicTrack;
  final int likesCount;
  final bool isLiked;
  final int sharesCount;
  final List<ReelCommentEntity> comments;

  const ReelEntity({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.videoAssetPath,
    required this.caption,
    required this.musicTrack,
    required this.likesCount,
    this.isLiked = false,
    this.sharesCount = 0,
    required this.comments,
  });

  ReelEntity copyWith({
    int? likesCount,
    bool? isLiked,
    int? sharesCount,
    List<ReelCommentEntity>? comments,
  }) {
    return ReelEntity(
      id: id,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      videoAssetPath: videoAssetPath,
      caption: caption,
      musicTrack: musicTrack,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      sharesCount: sharesCount ?? this.sharesCount,
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorName,
        authorUsername,
        authorAvatar,
        videoAssetPath,
        caption,
        musicTrack,
        likesCount,
        isLiked,
        sharesCount,
        comments,
      ];
}
