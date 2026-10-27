import 'package:equatable/equatable.dart';
import '../../../../core/indexing/pagination_cursor.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/story_entity.dart';

enum FeedStatus { initial, loading, loaded, error }

class FeedState extends Equatable {
  final FeedStatus status;
  final List<StoryEntity> stories;
  final List<PostEntity> posts;
  final PaginationCursor cursor;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? toastMessage;

  const FeedState({
    required this.status,
    required this.stories,
    required this.posts,
    required this.cursor,
    this.isLoadingMore = false,
    this.errorMessage,
    this.toastMessage,
  });

  factory FeedState.initial() {
    return FeedState(
      status: FeedStatus.initial,
      stories: const [],
      posts: const [],
      cursor: PaginationCursor.initial(),
    );
  }

  FeedState copyWith({
    FeedStatus? status,
    List<StoryEntity>? stories,
    List<PostEntity>? posts,
    PaginationCursor? cursor,
    bool? isLoadingMore,
    String? errorMessage,
    String? toastMessage,
  }) {
    return FeedState(
      status: status ?? this.status,
      stories: stories ?? this.stories,
      posts: posts ?? this.posts,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stories,
        posts,
        cursor,
        isLoadingMore,
        errorMessage,
        toastMessage,
      ];
}
