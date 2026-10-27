import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/indexing/indexed_collection.dart';
import '../models/reel_comment_model.dart';
import '../models/reel_model.dart';

abstract class ReelsLocalDataSource {
  Future<List<ReelModel>> getReels();
  Future<ReelModel> toggleLikeReel(String reelId);
  Future<ReelModel> addReelComment(String reelId, ReelCommentModel comment);
  Future<ReelModel> incrementShare(String reelId);
}

class ReelsLocalDataSourceImpl implements ReelsLocalDataSource {
  final SharedPreferences sharedPreferences;
  late final IndexedCollection<String, ReelModel> _reelsStore;
  bool _initialized = false;

  ReelsLocalDataSourceImpl({required this.sharedPreferences}) {
    _reelsStore = IndexedCollection<String, ReelModel>(
      keyExtractor: (reel) => reel.id,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final savedInteractions = _loadSavedInteractions();
    final defaultReels = _buildDefaultReels();

    for (final raw in defaultReels) {
      final saved = savedInteractions[raw.id];
      if (saved != null) {
        final isLiked = saved['isLiked'] as bool? ?? raw.isLiked;
        final likesCount = saved['likesCount'] as int? ?? raw.likesCount;
        final sharesCount = saved['sharesCount'] as int? ?? raw.sharesCount;

        List<ReelCommentModel> comments = [];
        if (saved['comments'] != null) {
          final list = (saved['comments'] as List<dynamic>)
              .map((c) => ReelCommentModel.fromJson(c as Map<String, dynamic>))
              .where((c) => c.id != 'rc1' && c.id != 'rc2' && c.id != 'rc3')
              .toList();
          comments = list;
        }

        final merged = ReelModel(
          id: raw.id,
          authorName: raw.authorName,
          authorUsername: raw.authorUsername,
          authorAvatar: raw.authorAvatar,
          videoAssetPath: raw.videoAssetPath,
          caption: raw.caption,
          musicTrack: raw.musicTrack,
          likesCount: likesCount,
          isLiked: isLiked,
          sharesCount: sharesCount,
          comments: comments,
        );
        _reelsStore.put(merged);
      } else {
        _reelsStore.put(raw);
      }
    }

    _initialized = true;
  }

  @override
  Future<List<ReelModel>> getReels() async {
    await _ensureInitialized();
    return _reelsStore.getAll();
  }

  @override
  Future<ReelModel> toggleLikeReel(String reelId) async {
    await _ensureInitialized();
    final reel = _reelsStore.get(reelId);
    if (reel == null) throw Exception('Reel $reelId not found');

    final newIsLiked = !reel.isLiked;
    final newLikesCount = newIsLiked ? reel.likesCount + 1 : (reel.likesCount - 1).clamp(0, 999999);

    final updated = ReelModel(
      id: reel.id,
      authorName: reel.authorName,
      authorUsername: reel.authorUsername,
      authorAvatar: reel.authorAvatar,
      videoAssetPath: reel.videoAssetPath,
      caption: reel.caption,
      musicTrack: reel.musicTrack,
      likesCount: newLikesCount,
      isLiked: newIsLiked,
      sharesCount: reel.sharesCount,
      comments: reel.comments.cast<ReelCommentModel>(),
    );

    _reelsStore.put(updated);
    await _persistReelInteraction(updated);
    return updated;
  }

  @override
  Future<ReelModel> addReelComment(String reelId, ReelCommentModel comment) async {
    await _ensureInitialized();
    final reel = _reelsStore.get(reelId);
    if (reel == null) throw Exception('Reel $reelId not found');

    final updatedComments = List<ReelCommentModel>.from(reel.comments)..add(comment);

    final updated = ReelModel(
      id: reel.id,
      authorName: reel.authorName,
      authorUsername: reel.authorUsername,
      authorAvatar: reel.authorAvatar,
      videoAssetPath: reel.videoAssetPath,
      caption: reel.caption,
      musicTrack: reel.musicTrack,
      likesCount: reel.likesCount,
      isLiked: reel.isLiked,
      sharesCount: reel.sharesCount,
      comments: updatedComments,
    );

    _reelsStore.put(updated);
    await _persistReelInteraction(updated);
    return updated;
  }

  @override
  Future<ReelModel> incrementShare(String reelId) async {
    await _ensureInitialized();
    final reel = _reelsStore.get(reelId);
    if (reel == null) throw Exception('Reel $reelId not found');

    final updated = ReelModel(
      id: reel.id,
      authorName: reel.authorName,
      authorUsername: reel.authorUsername,
      authorAvatar: reel.authorAvatar,
      videoAssetPath: reel.videoAssetPath,
      caption: reel.caption,
      musicTrack: reel.musicTrack,
      likesCount: reel.likesCount,
      isLiked: reel.isLiked,
      sharesCount: reel.sharesCount + 1,
      comments: reel.comments.cast<ReelCommentModel>(),
    );

    _reelsStore.put(updated);
    await _persistReelInteraction(updated);
    return updated;
  }

  Map<String, dynamic> _loadSavedInteractions() {
    final raw = sharedPreferences.getString(AppConstants.keyReelInteractions);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistReelInteraction(ReelModel reel) async {
    final current = _loadSavedInteractions();
    current[reel.id] = {
      'isLiked': reel.isLiked,
      'likesCount': reel.likesCount,
      'sharesCount': reel.sharesCount,
      'comments': reel.comments.map((c) => (c as ReelCommentModel).toJson()).toList(),
    };
    await sharedPreferences.setString(AppConstants.keyReelInteractions, jsonEncode(current));
  }

  List<ReelModel> _buildDefaultReels() {
    return [
      ReelModel(
        id: 'reel_1',
        authorName: 'Creative Motion Studio',
        authorUsername: '@motion_lab',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        videoAssetPath: 'assets/videos/reel_1.mp4',
        caption: 'Blender Open Movie series: Big Buck Bunny in action! Crisp 3D animation test 🐰✨',
        musicTrack: 'Original Mix • Blender Open Source Audio',
        likesCount: 3820,
        isLiked: false,
        sharesCount: 142,
        comments: const [],
      ),
      ReelModel(
        id: 'reel_2',
        authorName: 'Flora & Botanical Lab',
        authorUsername: '@flora_cinematics',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        videoAssetPath: 'assets/videos/reel_2.mp4',
        caption: 'Macro botanical photography of spring blooms unfolding in real time 🌸🌿 #nature #macro #visual',
        musicTrack: 'Peaceful Ambient Flora • Lo-Fi Chill',
        likesCount: 5120,
        isLiked: true,
        sharesCount: 310,
        comments: const [],
      ),
      ReelModel(
        id: 'reel_3',
        authorName: 'VFX & Rigging Lab',
        authorUsername: '@vfx_mastery',
        authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        videoAssetPath: 'assets/videos/reel_3.mp4',
        caption: 'Exploring character dynamics and physics-based lighting simulation. Full local asset bundle! ⚡',
        musicTrack: 'Cybernetic Pulse • Synthwave OST',
        likesCount: 2430,
        isLiked: false,
        sharesCount: 88,
        comments: const [],
      ),
      ReelModel(
        id: 'reel_4',
        authorName: 'Autonomous AI Systems',
        authorUsername: '@edge_vision',
        authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        videoAssetPath: 'assets/videos/reel_4.mp4',
        caption: 'Real-time vehicle detection & computer vision telemetry running on edge neural processors 🏎️🤖',
        musicTrack: 'Future Drive • Electronic Beats',
        likesCount: 8900,
        isLiked: false,
        sharesCount: 654,
        comments: const [],
      ),
      ReelModel(
        id: 'reel_5',
        authorName: 'Interactive Learning Lab',
        authorUsername: '@smart_classroom',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        videoAssetPath: 'assets/videos/reel_5.mp4',
        caption: 'Next generation collaborative robotics and smart interactive environments in action 🎓📚',
        musicTrack: 'Acoustic Inspiration • Classical Tech',
        likesCount: 1650,
        isLiked: false,
        sharesCount: 95,
        comments: [],
      ),
    ];
  }
}
