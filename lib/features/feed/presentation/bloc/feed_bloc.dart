import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/indexing/pagination_cursor.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/feed_interaction_usecases.dart';
import '../../domain/usecases/get_feed_posts_usecase.dart';
import '../../domain/usecases/get_stories_usecase.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetStoriesUseCase getStoriesUseCase;
  final GetFeedPostsUseCase getFeedPostsUseCase;
  final ToggleLikePostUseCase toggleLikePostUseCase;
  final ToggleBookmarkPostUseCase toggleBookmarkPostUseCase;
  final AddCommentUseCase addCommentUseCase;

  FeedBloc({
    required this.getStoriesUseCase,
    required this.getFeedPostsUseCase,
    required this.toggleLikePostUseCase,
    required this.toggleBookmarkPostUseCase,
    required this.addCommentUseCase,
  }) : super(FeedState.initial()) {
    on<LoadFeedInitialEvent>(_onLoadInitial);
    on<RefreshFeedEvent>(_onRefreshFeed);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<ToggleLikeEvent>(_onToggleLike);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<AddCommentEvent>(_onAddComment);
  }

  Future<void> _onLoadInitial(
    LoadFeedInitialEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(status: FeedStatus.loading));
    try {
      final stories = await getStoriesUseCase();
      final initialPosts = await getFeedPostsUseCase(pageIndex: 0, pageSize: 10);
      final cursor = PaginationCursor(
        pageIndex: 0,
        pageSize: 10,
        hasMore: initialPosts.length >= 10,
        totalIndexed: initialPosts.length,
      );

      emit(state.copyWith(
        status: FeedStatus.loaded,
        stories: stories,
        posts: initialPosts,
        cursor: cursor,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FeedStatus.error,
        errorMessage: 'Failed to load feed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final stories = await getStoriesUseCase();
      final refreshedPosts = await getFeedPostsUseCase(pageIndex: 0, pageSize: 10);
      final cursor = PaginationCursor(
        pageIndex: 0,
        pageSize: 10,
        hasMore: refreshedPosts.length >= 10,
        totalIndexed: refreshedPosts.length,
      );

      emit(state.copyWith(
        status: FeedStatus.loaded,
        stories: stories,
        posts: refreshedPosts,
        cursor: cursor,
        toastMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(toastMessage: 'Could not refresh feed: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMorePosts(
    LoadMorePostsEvent event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.cursor.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.cursor.pageIndex + 1;
      final newPosts = await getFeedPostsUseCase(
        pageIndex: nextPage,
        pageSize: state.cursor.pageSize,
      );

      final updatedPosts = [...state.posts, ...newPosts];
      final newCursor = state.cursor.next(
        fetchedCount: newPosts.length,
        totalCount: updatedPosts.length,
      );

      emit(state.copyWith(
        posts: updatedPosts,
        cursor: newCursor,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        toastMessage: 'Failed to load more posts',
      ));
    }
  }

  Future<void> _onToggleLike(
    ToggleLikeEvent event,
    Emitter<FeedState> emit,
  ) async {
    // Optimistic UI update
    final originalPosts = state.posts;
    final index = originalPosts.indexWhere((p) => p.id == event.postId);
    if (index == -1) return;

    final target = originalPosts[index];
    final optimisticLiked = !target.isLiked;
    final optimisticCount = optimisticLiked ? target.likesCount + 1 : (target.likesCount - 1).clamp(0, 999999);

    final updatedTarget = target.copyWith(
      isLiked: optimisticLiked,
      likesCount: optimisticCount,
    );

    final optimisticList = List<PostEntity>.from(originalPosts);
    optimisticList[index] = updatedTarget;
    emit(state.copyWith(posts: optimisticList, toastMessage: null));

    try {
      final serverPost = await toggleLikePostUseCase(event.postId);
      final finalPosts = List<PostEntity>.from(state.posts);
      final finalIndex = finalPosts.indexWhere((p) => p.id == event.postId);
      if (finalIndex != -1) {
        finalPosts[finalIndex] = serverPost;
        emit(state.copyWith(posts: finalPosts));
      }
    } on RateLimitFailure catch (r) {
      // Rollback optimistic update and notify rate limit
      emit(state.copyWith(
        posts: originalPosts,
        toastMessage: r.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        posts: originalPosts,
        toastMessage: 'Failed to update like status',
      ));
    }
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;
    final index = originalPosts.indexWhere((p) => p.id == event.postId);
    if (index == -1) return;

    final target = originalPosts[index];
    final updatedTarget = target.copyWith(isBookmarked: !target.isBookmarked);

    final updatedList = List<PostEntity>.from(originalPosts);
    updatedList[index] = updatedTarget;
    emit(state.copyWith(posts: updatedList));

    try {
      final serverPost = await toggleBookmarkPostUseCase(event.postId);
      final finalPosts = List<PostEntity>.from(state.posts);
      final finalIndex = finalPosts.indexWhere((p) => p.id == event.postId);
      if (finalIndex != -1) {
        finalPosts[finalIndex] = serverPost;
        emit(state.copyWith(posts: finalPosts));
      }
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, toastMessage: 'Failed to update bookmark'));
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final updatedPost = await addCommentUseCase(
        postId: event.postId,
        authorName: event.authorName,
        authorAvatar: event.authorAvatar,
        text: event.text.trim(),
      );

      final updatedPosts = state.posts.map((p) {
        return p.id == event.postId ? updatedPost : p;
      }).toList();

      emit(state.copyWith(posts: updatedPosts, toastMessage: 'Comment posted!'));
    } on RateLimitFailure catch (r) {
      emit(state.copyWith(toastMessage: r.message));
    } catch (e) {
      emit(state.copyWith(toastMessage: 'Failed to add comment: ${e.toString()}'));
    }
  }
}
