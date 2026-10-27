import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reel_comment_model.dart';
import '../models/reel_model.dart';

abstract class ReelsRemoteDataSource {
  Future<void> syncReelLike({
    required String reelId,
    required String userId,
    required bool isLiked,
  });

  Future<void> addReelComment({
    required String reelId,
    required ReelCommentModel comment,
  });

  Future<List<ReelCommentModel>> getReelComments(String reelId);

  Stream<List<ReelCommentModel>> streamReelComments(String reelId);

  Future<void> syncReel(ReelModel reel);

  Future<void> syncShare(String reelId);

  Future<List<ReelModel>> ensureReelsSeeded(
    List<ReelModel> localReels,
    String currentUserId,
  );
}

class ReelsRemoteDataSourceImpl implements ReelsRemoteDataSource {
  final FirebaseFirestore? firestore;

  ReelsRemoteDataSourceImpl({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> syncReelLike({
    required String reelId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      final reelRef = _db.collection('reels').doc(reelId);
      final likeDoc = reelRef.collection('likes').doc(userId);

      if (isLiked) {
        await likeDoc.set({
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await reelRef.set({
          'likesCount': FieldValue.increment(1),
          'likedUserIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Automatically clean up legacy hardcoded 'current_user' if present
        await reelRef.update({
          'likedUserIds': FieldValue.arrayRemove(['current_user']),
        }).catchError((_) {});
      } else {
        await likeDoc.delete().catchError((_) {});

        await reelRef.set({
          'likesCount': FieldValue.increment(-1),
          'likedUserIds': FieldValue.arrayRemove([userId, 'current_user']),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('[Firestore] Reel like synced: reel $reelId by user $userId ($isLiked)');
    } catch (e) {
      debugPrint('[Firestore] syncReelLike notice: $e');
    }
  }

  @override
  Future<void> addReelComment({
    required String reelId,
    required ReelCommentModel comment,
  }) async {
    try {
      final commentDoc = _db
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(comment.id);

      await commentDoc.set({
        ...comment.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtTimestamp': FieldValue.serverTimestamp(),
      });

      await _db.collection('reels').doc(reelId).set({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[Firestore] Reel comment synced for reel $reelId');
    } catch (e) {
      debugPrint('[Firestore] addReelComment notice: $e');
    }
  }

  @override
  Future<List<ReelCommentModel>> getReelComments(String reelId) async {
    try {
      final snapshot = await _db
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .get();

      final list = snapshot.docs
          .map((doc) => ReelCommentModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (e) {
      debugPrint('[Firestore] getReelComments notice: $e');
      return [];
    }
  }

  @override
  Stream<List<ReelCommentModel>> streamReelComments(String reelId) {
    return _db
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReelCommentModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  @override
  Future<void> syncReel(ReelModel reel) async {
    try {
      await _db
          .collection('reels')
          .doc(reel.id)
          .set(reel.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] syncReel notice: $e');
    }
  }

  @override
  Future<void> syncShare(String reelId) async {
    try {
      await _db.collection('reels').doc(reelId).set({
        'sharesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] syncShare notice: $e');
    }
  }

  @override
  Future<List<ReelModel>> ensureReelsSeeded(
    List<ReelModel> localReels,
    String currentUserId,
  ) async {
    final List<ReelModel> results = [];
    for (final reel in localReels) {
      try {
        final reelRef = _db.collection('reels').doc(reel.id);
        final doc = await reelRef.get();

        if (!doc.exists) {
          // Explicitly create the document in the 'reels' collection in Firestore!
          final data = {
            'id': reel.id,
            'authorName': reel.authorName,
            'authorUsername': reel.authorUsername,
            'authorAvatar': reel.authorAvatar,
            'videoAssetPath': reel.videoAssetPath,
            'caption': reel.caption,
            'musicTrack': reel.musicTrack,
            'likesCount': reel.likesCount,
            'commentsCount': 0,
            'sharesCount': reel.sharesCount,
            'likedUserIds': reel.isLiked && currentUserId.isNotEmpty ? [currentUserId] : <String>[],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await reelRef.set(data, SetOptions(merge: true));
          results.add(reel);
          debugPrint('[Firestore] Initialized reel document in collection "reels": ${reel.id}');
        } else {
          // Document exists in Firestore reels collection: merge live likesCount, commentsCount, and likedUserIds
          final data = doc.data() ?? {};
          final likesCount = (data['likesCount'] as num?)?.toInt() ?? reel.likesCount;
          final sharesCount = (data['sharesCount'] as num?)?.toInt() ?? reel.sharesCount;
          final likedUserIds = List<String>.from(data['likedUserIds'] ?? []);
          final isLiked = currentUserId.isNotEmpty && likedUserIds.contains(currentUserId);

          results.add(ReelModel(
            id: reel.id,
            authorName: data['authorName'] as String? ?? reel.authorName,
            authorUsername: data['authorUsername'] as String? ?? reel.authorUsername,
            authorAvatar: data['authorAvatar'] as String? ?? reel.authorAvatar,
            videoAssetPath: data['videoAssetPath'] as String? ?? reel.videoAssetPath,
            caption: data['caption'] as String? ?? reel.caption,
            musicTrack: data['musicTrack'] as String? ?? reel.musicTrack,
            likesCount: likesCount,
            isLiked: isLiked,
            sharesCount: sharesCount,
            comments: reel.comments.cast<ReelCommentModel>(),
          ));
        }
      } catch (e) {
        debugPrint('[Firestore] ensureReelsSeeded notice: $e');
        results.add(reel);
      }
    }
    return results;
  }
}
