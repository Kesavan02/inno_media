import '../entities/reel_entity.dart';
import '../repositories/reels_repository.dart';

class GetReelsUseCase {
  final ReelsRepository repository;
  GetReelsUseCase(this.repository);

  Future<List<ReelEntity>> call() => repository.getReels();
}

class ToggleLikeReelUseCase {
  final ReelsRepository repository;
  ToggleLikeReelUseCase(this.repository);

  Future<ReelEntity> call(String reelId) => repository.toggleLikeReel(reelId);
}

class AddReelCommentUseCase {
  final ReelsRepository repository;
  AddReelCommentUseCase(this.repository);

  Future<ReelEntity> call({
    required String reelId,
    required String authorName,
    required String authorAvatar,
    required String text,
  }) {
    return repository.addReelComment(
      reelId: reelId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      text: text,
    );
  }
}

class ShareReelUseCase {
  final ReelsRepository repository;
  ShareReelUseCase(this.repository);

  Future<ReelEntity> call(String reelId) => repository.shareReel(reelId);
}
