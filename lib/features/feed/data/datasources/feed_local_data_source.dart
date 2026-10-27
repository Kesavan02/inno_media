import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/indexing/indexed_collection.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';

abstract class FeedLocalDataSource {
  Future<List<StoryModel>> getStories();
  Future<List<PostModel>> getPostsPaged({required int pageIndex, required int pageSize});
  Future<PostModel> toggleLike(String postId);
  Future<PostModel> toggleBookmark(String postId);
  Future<PostModel> addComment(String postId, CommentModel comment);
}

class FeedLocalDataSourceImpl implements FeedLocalDataSource {
  final SharedPreferences sharedPreferences;
  late final IndexedCollection<String, PostModel> _indexedPostStore;
  final List<StoryModel> _stories = [];
  bool _initialized = false;

  FeedLocalDataSourceImpl({required this.sharedPreferences}) {
    _indexedPostStore = IndexedCollection<String, PostModel>(
      keyExtractor: (post) => post.id,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Load persisted state (likes, bookmarks, comments)
    final savedInteractions = _loadSavedInteractions();

    final rawPosts = _buildInitialSamplePosts();
    for (final raw in rawPosts) {
      final savedData = savedInteractions[raw.id];
      if (savedData != null) {
        final isLiked = savedData['isLiked'] as bool? ?? raw.isLiked;
        final isBookmarked = savedData['isBookmarked'] as bool? ?? raw.isBookmarked;
        final likesCount = savedData['likesCount'] as int? ?? raw.likesCount;
        
        List<CommentModel> comments = [];
        if (savedData['comments'] != null) {
          final list = (savedData['comments'] as List<dynamic>)
              .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
              .where((c) => c.id != 'c1' && c.id != 'c2' && c.id != 'c3' && c.id != 'c4')
              .toList();
          comments = list;
        }

        final merged = PostModel(
          id: raw.id,
          authorId: raw.authorId,
          authorName: raw.authorName,
          authorUsername: raw.authorUsername,
          authorAvatar: raw.authorAvatar,
          location: raw.location,
          caption: raw.caption,
          tags: raw.tags,
          imageUrl: raw.imageUrl,
          likesCount: likesCount,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
          comments: comments,
          createdAt: raw.createdAt,
        );
        _indexedPostStore.put(merged);
      } else {
        _indexedPostStore.put(raw);
      }
    }

    _stories.addAll(_buildInitialSampleStories());
    _initialized = true;
  }

  @override
  Future<List<StoryModel>> getStories() async {
    await _ensureInitialized();
    return List.unmodifiable(_stories);
  }

  @override
  Future<List<PostModel>> getPostsPaged({required int pageIndex, required int pageSize}) async {
    await _ensureInitialized();
    return _indexedPostStore.getPaged(pageIndex: pageIndex, pageSize: pageSize);
  }

  @override
  Future<PostModel> toggleLike(String postId) async {
    await _ensureInitialized();
    final post = _indexedPostStore.get(postId);
    if (post == null) throw Exception('Post $postId not found');

    final newIsLiked = !post.isLiked;
    final newLikesCount = newIsLiked ? post.likesCount + 1 : (post.likesCount - 1).clamp(0, 999999);

    final updated = PostModel(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorUsername: post.authorUsername,
      authorAvatar: post.authorAvatar,
      location: post.location,
      caption: post.caption,
      tags: post.tags,
      imageUrl: post.imageUrl,
      likesCount: newLikesCount,
      isLiked: newIsLiked,
      isBookmarked: post.isBookmarked,
      comments: post.comments.cast<CommentModel>(),
      createdAt: post.createdAt,
    );

    _indexedPostStore.put(updated);
    await _persistPostInteraction(updated);
    return updated;
  }

  @override
  Future<PostModel> toggleBookmark(String postId) async {
    await _ensureInitialized();
    final post = _indexedPostStore.get(postId);
    if (post == null) throw Exception('Post $postId not found');

    final updated = PostModel(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorUsername: post.authorUsername,
      authorAvatar: post.authorAvatar,
      location: post.location,
      caption: post.caption,
      tags: post.tags,
      imageUrl: post.imageUrl,
      likesCount: post.likesCount,
      isLiked: post.isLiked,
      isBookmarked: !post.isBookmarked,
      comments: post.comments.cast<CommentModel>(),
      createdAt: post.createdAt,
    );

    _indexedPostStore.put(updated);
    await _persistPostInteraction(updated);
    return updated;
  }

  @override
  Future<PostModel> addComment(String postId, CommentModel comment) async {
    await _ensureInitialized();
    final post = _indexedPostStore.get(postId);
    if (post == null) throw Exception('Post $postId not found');

    final updatedComments = List<CommentModel>.from(post.comments)..add(comment);

    final updated = PostModel(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorUsername: post.authorUsername,
      authorAvatar: post.authorAvatar,
      location: post.location,
      caption: post.caption,
      tags: post.tags,
      imageUrl: post.imageUrl,
      likesCount: post.likesCount,
      isLiked: post.isLiked,
      isBookmarked: post.isBookmarked,
      comments: updatedComments,
      createdAt: post.createdAt,
    );

    _indexedPostStore.put(updated);
    await _persistPostInteraction(updated);
    return updated;
  }

  Map<String, dynamic> _loadSavedInteractions() {
    final raw = sharedPreferences.getString(AppConstants.keyFeedInteractions);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistPostInteraction(PostModel post) async {
    final current = _loadSavedInteractions();
    current[post.id] = {
      'isLiked': post.isLiked,
      'isBookmarked': post.isBookmarked,
      'likesCount': post.likesCount,
      'comments': post.comments.map((c) => (c as CommentModel).toJson()).toList(),
    };
    await sharedPreferences.setString(AppConstants.keyFeedInteractions, jsonEncode(current));
  }

  List<StoryModel> _buildInitialSampleStories() {
    return [
      StoryModel(
        id: 'story_1',
        authorName: 'You',
        authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
        mediaUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80',
        caption: 'Working late on Clean Architecture & BLoC state flows 🚀',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      StoryModel(
        id: 'story_2',
        authorName: 'Elena Rostova',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        mediaUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
        caption: 'Sunset in Santorini, Greece. Mind blown!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      StoryModel(
        id: 'story_3',
        authorName: 'Dev Marcus',
        authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        mediaUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=1200&q=80',
        caption: 'New mechanical setup with split keyboard and 4k vertical display 💻',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      StoryModel(
        id: 'story_4',
        authorName: 'Sophia Chen',
        authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
        mediaUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
        caption: 'Minimalist Scandinavian studio workspace vibe ✨',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      StoryModel(
        id: 'story_5',
        authorName: 'Liam Vance',
        authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        mediaUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
        caption: 'Prototyping custom microchips and neural accelerators',
        timestamp: DateTime.now().subtract(const Duration(hours: 9)),
      ),
    ];
  }

  List<PostModel> _buildInitialSamplePosts() {
    return [
      PostModel(
        id: 'post_101',
        authorId: 'usr_elena',
        authorName: 'Elena Rostova',
        authorUsername: '@elena_designs',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        location: 'Kyoto, Japan',
        caption: 'Embracing minimalist architecture in Kyoto. The play between natural sunlight, cedar timber, and negative space is pure poetry. Less is truly more.',
        tags: ['#architecture', '#minimalism', '#japan', '#design'],
        imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1200&q=80',
        likesCount: 1420,
        isLiked: false,
        comments: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      PostModel(
        id: 'post_102',
        authorId: 'usr_marcus',
        authorName: 'Dev Marcus',
        authorUsername: '@marcus_tech',
        authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        location: 'Zurich, Switzerland',
        caption: 'Clean Architecture with BLoC state management in Flutter is such a joy when you master inverted dependencies and stream transformations. Here is our new developer workbench!',
        tags: ['#flutter', '#cleanarchitecture', '#bloc', '#developer'],
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=1200&q=80',
        likesCount: 954,
        isLiked: true,
        comments: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
      PostModel(
        id: 'post_103',
        authorId: 'usr_sophia',
        authorName: 'Sophia Chen',
        authorUsername: '@sophia_visuals',
        authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
        location: 'Nordic Coast, Norway',
        caption: 'Morning mist over the fjords. The silence out here lets the mind reset and refocus. Captured during my field expedition.',
        tags: ['#norway', '#fjords', '#nature', '#cinematic'],
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
        likesCount: 2310,
        isLiked: false,
        comments: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      PostModel(
        id: 'post_104',
        authorId: 'usr_liam',
        authorName: 'Liam Vance',
        authorUsername: '@liam_cyber',
        authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        location: 'Silicon Valley, CA',
        caption: 'Synthesized wave form generation and neural audio processors. Hardware engineering meets high-taste product design.',
        tags: ['#hardware', '#audio', '#synth', '#engineering'],
        imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
        likesCount: 680,
        isLiked: false,
        comments: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
    ];
  }
}
