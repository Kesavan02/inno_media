import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../domain/entities/reel_entity.dart';

class ReelActionSidebar extends StatefulWidget {
  final ReelEntity reel;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  const ReelActionSidebar({
    super.key,
    required this.reel,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onShare,
  });

  @override
  State<ReelActionSidebar> createState() => _ReelActionSidebarState();
}

class _ReelActionSidebarState extends State<ReelActionSidebar> with SingleTickerProviderStateMixin {
  late AnimationController _discAnimController;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _discAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author Profile with badge
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(reel.authorAvatar),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Like Button
        TactileBounce(
          key: Key('reel_like_btn_${reel.id}'),
          onTap: widget.onToggleLike,
          child: Column(
            children: [
              Icon(
                reel.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: reel.isLiked ? AppColors.primary : Colors.white,
                size: 32,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 8)],
              ),
              const SizedBox(height: 4),
              Text(
                reel.likesCount.toString(),
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Comment Button
        TactileBounce(
          key: Key('reel_comment_btn_${reel.id}'),
          onTap: widget.onOpenComments,
          child: Column(
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 28,
                shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
              ),
              const SizedBox(height: 4),
              Text(
                reel.comments.length.toString(),
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Share Button
        TactileBounce(
          key: Key('reel_share_btn_${reel.id}'),
          onTap: widget.onShare,
          child: Column(
            children: [
              const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 28,
                shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
              ),
              const SizedBox(height: 4),
              Text(
                reel.sharesCount > 0 ? reel.sharesCount.toString() : 'Share',
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Spinning Music Vinyl Disc
        AnimatedBuilder(
          animation: _discAnimController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _discAnimController.value * 2 * math.pi,
              child: child,
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.grey.shade900, Colors.black, Colors.grey.shade800],
                stops: const [0.3, 0.7, 1.0],
              ),
              border: Border.all(color: Colors.white38, width: 2.0),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
