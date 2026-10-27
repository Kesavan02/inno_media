import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object?> get props => [];
}

class LoadFeedInitialEvent extends FeedEvent {}

class RefreshFeedEvent extends FeedEvent {}

class LoadMorePostsEvent extends FeedEvent {}

class ToggleLikeEvent extends FeedEvent {
  final String postId;
  const ToggleLikeEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class ToggleBookmarkEvent extends FeedEvent {
  final String postId;
  const ToggleBookmarkEvent(this.postId);
  @override
  List<Object?> get props => [postId];
}

class AddCommentEvent extends FeedEvent {
  final String postId;
  final String text;
  final String authorName;
  final String authorAvatar;

  const AddCommentEvent({
    required this.postId,
    required this.text,
    required this.authorName,
    required this.authorAvatar,
  });

  @override
  List<Object?> get props => [postId, text, authorName, authorAvatar];
}
