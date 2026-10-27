import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class ToggleLikePostUseCase {
  final FeedRepository repository;
  ToggleLikePostUseCase(this.repository);

  Future<PostEntity> call(String postId) => repository.toggleLike(postId);
}

class ToggleBookmarkPostUseCase {
  final FeedRepository repository;
  ToggleBookmarkPostUseCase(this.repository);

  Future<PostEntity> call(String postId) => repository.toggleBookmark(postId);
}

class AddCommentUseCase {
  final FeedRepository repository;
  AddCommentUseCase(this.repository);

  Future<PostEntity> call({
    required String postId,
    required String authorName,
    required String authorAvatar,
    required String text,
  }) {
    return repository.addComment(
      postId: postId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      text: text,
    );
  }
}
