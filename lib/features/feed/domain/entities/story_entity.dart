import 'package:equatable/equatable.dart';

class StoryEntity extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String mediaUrl;
  final String caption;
  final DateTime timestamp;
  final bool isViewed;

  const StoryEntity({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.mediaUrl,
    required this.caption,
    required this.timestamp,
    this.isViewed = false,
  });

  StoryEntity copyWith({bool? isViewed}) {
    return StoryEntity(
      id: id,
      authorName: authorName,
      authorAvatar: authorAvatar,
      mediaUrl: mediaUrl,
      caption: caption,
      timestamp: timestamp,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [id, authorName, authorAvatar, mediaUrl, caption, timestamp, isViewed];
}
