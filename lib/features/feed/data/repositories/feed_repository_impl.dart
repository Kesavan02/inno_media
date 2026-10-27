import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/rate_limiter/rate_limiter.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_local_data_source.dart';
import '../datasources/feed_remote_data_source.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../models/comment_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedLocalDataSource localDataSource;
  final FeedRemoteDataSource? remoteDataSource;
  final AuthLocalDataSource? authLocalDataSource;
  final RateLimiter rateLimiter;

  FeedRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
    this.authLocalDataSource,
    required this.rateLimiter,
  });

  @override
  Future<List<StoryEntity>> getStories() async {
    try {
      return await localDataSource.getStories();
    } catch (e) {
      throw ServerFailure('Failed to load stories: ${e.toString()}');
    }
  }

  @override
  Future<List<PostEntity>> getPostsPaged({required int pageIndex, required int pageSize}) async {
    try {
      final localPosts = await localDataSource.getPostsPaged(pageIndex: pageIndex, pageSize: pageSize);
      if (remoteDataSource != null) {
        final user = await authLocalDataSource?.getCurrentUser();
        final userId = user?.id ?? '';
        return await remoteDataSource!.ensurePostsSeeded(localPosts, userId);
      }
      return localPosts;
    } catch (e) {
      throw ServerFailure('Failed to load posts: ${e.toString()}');
    }
  }


  @override
  Future<PostEntity> toggleLike(String postId) async {
    try {
      // Data flow rate limiter: prevent like spamming
      rateLimiter.acquire('like_post_$postId');
      final updated = await localDataSource.toggleLike(postId);

      // Asynchronously sync like status to Firestore with real user ID
      if (remoteDataSource != null) {
        final user = await authLocalDataSource?.getCurrentUser();
        final userId = user?.id ?? 'usr_guest';
        remoteDataSource!
            .syncPostLike(postId, userId, updated.isLiked)
            .catchError((_) {});
      }

      return updated;
    } on RateLimitException catch (e) {
      throw RateLimitFailure(e.message, e.retryAfter);
    } catch (e) {
      throw ServerFailure('Failed to update like: ${e.toString()}');
    }
  }

  @override
  Future<PostEntity> toggleBookmark(String postId) async {
    try {
      return await localDataSource.toggleBookmark(postId);
    } catch (e) {
      throw ServerFailure('Failed to update bookmark: ${e.toString()}');
    }
  }

  @override
  Future<PostEntity> addComment({
    required String postId,
    required String authorName,
    required String authorAvatar,
    required String text,
  }) async {
    try {
      // Data flow rate limit: 1 comment per 2 seconds per post
      rateLimiter.acquire('comment_post_$postId');

      final user = await authLocalDataSource?.getCurrentUser();
      final resolvedName = authorName.isNotEmpty ? authorName : (user?.fullName ?? 'Alex Johnson');
      final resolvedAvatar = authorAvatar.isNotEmpty ? authorAvatar : (user?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80');

      final commentModel = CommentModel(
        id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
        authorName: resolvedName,
        authorAvatar: resolvedAvatar,
        text: text,
        timestamp: DateTime.now(),
      );

      final updated = await localDataSource.addComment(postId, commentModel);

      // Asynchronously sync comment to Firestore
      if (remoteDataSource != null) {
        remoteDataSource!.addComment(postId, commentModel).catchError((_) {});
      }

      return updated;
    } on RateLimitException catch (e) {
      throw RateLimitFailure(e.message, e.retryAfter);
    } catch (e) {
      throw ServerFailure('Failed to submit comment: ${e.toString()}');
    }
  }
}
