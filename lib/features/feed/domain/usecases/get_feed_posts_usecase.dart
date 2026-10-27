import '../entities/post_entity.dart';
import '../repositories/feed_repository.dart';

class GetFeedPostsUseCase {
  final FeedRepository repository;
  GetFeedPostsUseCase(this.repository);

  Future<List<PostEntity>> call({required int pageIndex, required int pageSize}) {
    return repository.getPostsPaged(pageIndex: pageIndex, pageSize: pageSize);
  }
}
