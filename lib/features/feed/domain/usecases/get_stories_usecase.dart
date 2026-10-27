import '../entities/story_entity.dart';
import '../repositories/feed_repository.dart';

class GetStoriesUseCase {
  final FeedRepository repository;
  GetStoriesUseCase(this.repository);

  Future<List<StoryEntity>> call() => repository.getStories();
}
