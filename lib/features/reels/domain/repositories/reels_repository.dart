import '../entities/reel_entity.dart';

abstract class ReelsRepository {
  Future<List<ReelEntity>> getReels();
  Future<ReelEntity> toggleLikeReel(String reelId);
  Future<ReelEntity> addReelComment({
    required String reelId,
    required String authorName,
    required String authorAvatar,
    required String text,
  });
  Future<ReelEntity> shareReel(String reelId);
}
