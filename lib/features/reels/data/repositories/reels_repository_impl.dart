import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/rate_limiter/rate_limiter.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/reel_entity.dart';
import '../../domain/repositories/reels_repository.dart';
import '../datasources/reels_local_data_source.dart';
import '../datasources/reels_remote_data_source.dart';
import '../models/reel_comment_model.dart';

class ReelsRepositoryImpl implements ReelsRepository {
  final ReelsLocalDataSource localDataSource;
  final ReelsRemoteDataSource? remoteDataSource;
  final AuthLocalDataSource? authLocalDataSource;
  final RateLimiter rateLimiter;

  ReelsRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
    this.authLocalDataSource,
    required this.rateLimiter,
  });

  @override
  Future<List<ReelEntity>> getReels() async {
    try {
      final localReels = await localDataSource.getReels();
      if (remoteDataSource != null) {
        final user = await authLocalDataSource?.getCurrentUser();
        final userId = user?.id ?? '';
        return await remoteDataSource!.ensureReelsSeeded(localReels, userId);
      }
      return localReels;
    } catch (e) {
      throw ServerFailure('Failed to load reels: ${e.toString()}');
    }
  }

  @override
  Future<ReelEntity> toggleLikeReel(String reelId) async {
    try {
      rateLimiter.acquire('like_reel_$reelId');
      final updated = await localDataSource.toggleLikeReel(reelId);

      // Asynchronously sync like status to Firestore with real user ID
      if (remoteDataSource != null) {
        final user = await authLocalDataSource?.getCurrentUser();
        final userId = user?.id ?? 'usr_guest';
        remoteDataSource!
            .syncReelLike(reelId: reelId, userId: userId, isLiked: updated.isLiked)
            .catchError((_) {});
      }

      return updated;
    } on RateLimitException catch (e) {
      throw RateLimitFailure(e.message, e.retryAfter);
    } catch (e) {
      throw ServerFailure('Failed to like reel: ${e.toString()}');
    }
  }

  @override
  Future<ReelEntity> addReelComment({
    required String reelId,
    required String authorName,
    required String authorAvatar,
    required String text,
  }) async {
    try {
      rateLimiter.acquire('comment_reel_$reelId');

      final user = await authLocalDataSource?.getCurrentUser();
      final resolvedName = authorName.isNotEmpty ? authorName : (user?.fullName ?? 'Alex Johnson');
      final resolvedAvatar = authorAvatar.isNotEmpty ? authorAvatar : (user?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80');

      final commentModel = ReelCommentModel(
        id: 'rc_${DateTime.now().millisecondsSinceEpoch}',
        authorName: resolvedName,
        authorAvatar: resolvedAvatar,
        text: text,
        createdAt: DateTime.now(),
      );

      final updated = await localDataSource.addReelComment(reelId, commentModel);

      // Asynchronously sync comment to Firestore
      if (remoteDataSource != null) {
        remoteDataSource!
            .addReelComment(reelId: reelId, comment: commentModel)
            .catchError((_) {});
      }

      return updated;
    } on RateLimitException catch (e) {
      throw RateLimitFailure(e.message, e.retryAfter);
    } catch (e) {
      throw ServerFailure('Failed to add reel comment: ${e.toString()}');
    }
  }

  @override
  Future<ReelEntity> shareReel(String reelId) async {
    try {
      final updated = await localDataSource.incrementShare(reelId);

      if (remoteDataSource != null) {
        remoteDataSource!.syncShare(reelId).catchError((_) {});
      }

      return updated;
    } catch (e) {
      throw ServerFailure('Failed to share reel: ${e.toString()}');
    }
  }
}
