import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

abstract class FeedRemoteDataSource {
  Future<void> syncPostLike(String postId, String userId, bool isLiked);
  Future<void> addComment(String postId, CommentModel comment);
  Future<List<CommentModel>> getComments(String postId);
  Stream<List<CommentModel>> streamComments(String postId);
  Future<void> syncPost(PostModel post);
  Future<List<PostModel>> ensurePostsSeeded(
    List<PostModel> localPosts,
    String currentUserId,
  );
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final FirebaseFirestore? firestore;

  FeedRemoteDataSourceImpl({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> syncPostLike(String postId, String userId, bool isLiked) async {
    try {
      final postRef = _db.collection('posts').doc(postId);
      final likeDoc = postRef.collection('likes').doc(userId);

      if (isLiked) {
        await likeDoc.set({
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await postRef.set({
          'likesCount': FieldValue.increment(1),
          'likedUserIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Automatically clean up legacy hardcoded 'current_user' if present
        await postRef.update({
          'likedUserIds': FieldValue.arrayRemove(['current_user']),
        }).catchError((_) {});
      } else {
        await likeDoc.delete().catchError((_) {});

        await postRef.set({
          'likesCount': FieldValue.increment(-1),
          'likedUserIds': FieldValue.arrayRemove([userId, 'current_user']),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('[Firestore] Post like synced for post $postId by user $userId ($isLiked)');
    } catch (e) {
      debugPrint('[Firestore] syncPostLike notice: $e');
    }
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    try {
      final commentDoc = _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(comment.id);

      await commentDoc.set({
        ...comment.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtTimestamp': FieldValue.serverTimestamp(),
      });

      // Increment comment count on the parent post document
      await _db.collection('posts').doc(postId).set({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[Firestore] Comment synced for post $postId');
    } catch (e) {
      debugPrint('[Firestore] addComment notice: $e');
    }
  }

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final snapshot = await _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      final list = snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } catch (e) {
      debugPrint('[Firestore] getComments notice: $e');
      return [];
    }
  }

  @override
  Stream<List<CommentModel>> streamComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  @override
  Future<void> syncPost(PostModel post) async {
    try {
      await _db
          .collection('posts')
          .doc(post.id)
          .set(post.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] syncPost notice: $e');
    }
  }

  @override
  Future<List<PostModel>> ensurePostsSeeded(
    List<PostModel> localPosts,
    String currentUserId,
  ) async {
    final List<PostModel> results = [];
    for (final post in localPosts) {
      try {
        final postRef = _db.collection('posts').doc(post.id);
        final doc = await postRef.get();

        if (!doc.exists) {
          // Explicitly create the document in the 'posts' collection in Firestore!
          final data = {
            'id': post.id,
            'authorId': post.authorId,
            'authorName': post.authorName,
            'authorUsername': post.authorUsername,
            'authorAvatar': post.authorAvatar,
            'location': post.location,
            'caption': post.caption,
            'tags': post.tags,
            'imageUrl': post.imageUrl,
            'likesCount': post.likesCount,
            'commentsCount': 0,
            'likedUserIds': post.isLiked && currentUserId.isNotEmpty ? [currentUserId] : <String>[],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await postRef.set(data, SetOptions(merge: true));
          results.add(post);
          debugPrint('[Firestore] Initialized post document in collection "posts": ${post.id}');
        } else {
          // Document exists in Firestore posts collection: merge live likesCount and likedUserIds
          final data = doc.data() ?? {};
          final likesCount = (data['likesCount'] as num?)?.toInt() ?? post.likesCount;
          final likedUserIds = List<String>.from(data['likedUserIds'] ?? []);
          final isLiked = currentUserId.isNotEmpty && likedUserIds.contains(currentUserId);

          results.add(PostModel(
            id: post.id,
            authorId: post.authorId,
            authorName: data['authorName'] as String? ?? post.authorName,
            authorUsername: data['authorUsername'] as String? ?? post.authorUsername,
            authorAvatar: data['authorAvatar'] as String? ?? post.authorAvatar,
            location: data['location'] as String? ?? post.location,
            caption: data['caption'] as String? ?? post.caption,
            tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? post.tags,
            imageUrl: data['imageUrl'] as String? ?? post.imageUrl,
            likesCount: likesCount,
            isLiked: isLiked,
            isBookmarked: post.isBookmarked,
            comments: post.comments.cast<CommentModel>(),
            createdAt: post.createdAt,
          ));
        }
      } catch (e) {
        debugPrint('[Firestore] ensurePostsSeeded notice: $e');
        results.add(post);
      }
    }
    return results;
  }
}

