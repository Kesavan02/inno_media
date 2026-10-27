import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/native_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../domain/entities/post_entity.dart';
import 'comment_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final PostEntity post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final Function(String text) onAddComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onAddComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  bool _showBurstHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showBurstHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onDoubleTapPhoto() {
    setState(() => _showBurstHeart = true);
    _heartAnimController.forward(from: 0.0);
    if (!widget.post.isLiked) {
      widget.onToggleLike();
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        post: widget.post,
        onAddComment: widget.onAddComment,
      ),
    );
  }

  void _sharePost() {
    NativeShareService.sharePost(
      postId: widget.post.id,
      imageUrl: widget.post.imageUrl,
      caption: widget.post.caption,
      authorUsername: widget.post.authorUsername,
    );
  }


  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post.authorAvatar),
                  backgroundColor: AppColors.surfaceElevated,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: AppTypography.titleLarge.copyWith(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.secondary, size: 14),
                        ],
                      ),
                      Text(
                        '${post.authorUsername} • ${post.location}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post Media Image with double-tap like animation
          GestureDetector(
            onDoubleTap: _onDoubleTapPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surfaceElevated,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),

                // Double tap animated heart burst
                if (_showBurstHeart)
                  ScaleTransition(
                    scale: _heartScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 72,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions Bar (Like, Comment, Share, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Like Button
                TactileBounce(
                  key: Key('like_btn_${post.id}'),
                  onTap: widget.onToggleLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: post.isLiked ? AppColors.primary : AppColors.textPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.likesCount.toString(),
                        style: AppTypography.labelLarge.copyWith(
                          color: post.isLiked ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Comment Button
                TactileBounce(
                  key: Key('comment_btn_${post.id}'),
                  onTap: _openComments,
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textPrimary, size: 22),
                      const SizedBox(width: 6),
                      Text(post.comments.length.toString(), style: AppTypography.labelLarge),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Share Button
                TactileBounce(
                  key: Key('share_btn_${post.id}'),
                  onTap: _sharePost,
                  child: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
                ),

                const Spacer(),

                // Bookmark Button
                TactileBounce(
                  key: Key('bookmark_btn_${post.id}'),
                  onTap: widget.onToggleBookmark,
                  child: Icon(
                    post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: post.isBookmarked ? AppColors.secondary : AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Caption & Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: '${post.authorUsername} ',
                    style: AppTypography.titleLarge.copyWith(fontSize: 14),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),

          // Tag chips
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.tags.map((tag) {
                  return Text(
                    tag,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),

          // View comments link
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: GestureDetector(
                onTap: _openComments,
                child: Text(
                  'View all ${post.comments.length} comments',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 14),
            child: Text(
              DateFormat.yMMMd().format(post.createdAt).toUpperCase(),
              style: AppTypography.tagCaps.copyWith(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
