import '../entities/post_entity.dart';
import '../entities/story_entity.dart';

abstract class FeedRepository {
  Future<List<StoryEntity>> getStories();
  Future<List<PostEntity>> getPostsPaged({required int pageIndex, required int pageSize});
  Future<PostEntity> toggleLike(String postId);
  Future<PostEntity> toggleBookmark(String postId);
  Future<PostEntity> addComment({
    required String postId,
    required String authorName,
    required String authorAvatar,
    required String text,
  });
}
