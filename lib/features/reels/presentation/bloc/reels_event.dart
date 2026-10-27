import 'package:equatable/equatable.dart';

abstract class ReelsEvent extends Equatable {
  const ReelsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReelsEvent extends ReelsEvent {}

class ChangeActiveReelIndexEvent extends ReelsEvent {
  final int index;
  const ChangeActiveReelIndexEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class ToggleLikeReelEvent extends ReelsEvent {
  final String reelId;
  const ToggleLikeReelEvent(this.reelId);
  @override
  List<Object?> get props => [reelId];
}

class AddReelCommentEvent extends ReelsEvent {
  final String reelId;
  final String text;
  final String authorName;
  final String authorAvatar;

  const AddReelCommentEvent({
    required this.reelId,
    required this.text,
    required this.authorName,
    required this.authorAvatar,
  });

  @override
  List<Object?> get props => [reelId, text, authorName, authorAvatar];
}

class ShareReelEvent extends ReelsEvent {
  final String reelId;
  const ShareReelEvent(this.reelId);
  @override
  List<Object?> get props => [reelId];
}
