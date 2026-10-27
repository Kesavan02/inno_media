import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/native_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../domain/entities/story_entity.dart';

/// Fullscreen Story Viewer featuring horizontal slide navigation between users,
/// automated timed progression, single clean progress bar, left/right tap triggers,
/// and interactive direct messaging with keyboard support and auto-pause.
class StoryViewerDialog extends StatefulWidget {
  final List<StoryEntity> stories;
  final int initialIndex;

  const StoryViewerDialog({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final PageController _pageController;
  late final AnimationController _progressController;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.isEmpty ? 0 : widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextUserStory();
      }
    });

    _messageController.addListener(() {
      if (mounted) setState(() {});
    });

    // Pause story timer while typing/focused; resume when keyboard dismisses
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        _progressController.stop();
      } else {
        if (!_progressController.isAnimating) {
          _progressController.forward();
        }
      }
      if (mounted) setState(() {});
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _sendMessage(String authorName, [String? explicitText]) {
    final text = (explicitText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _messageFocusNode.unfocus();
    _progressController.forward();

    // Show confirmation banner that message was sent
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              explicitText != null ? Icons.favorite_rounded : Icons.check_circle_rounded,
              color: explicitText != null ? AppColors.primary : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                explicitText != null
                    ? 'Sent $explicitText reaction to "$authorName"'
                    : 'Message sent successfully to "$authorName"',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToNextUserStory() {
    if (_messageFocusNode.hasFocus) return; // Do not auto-advance while user is typing

    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _goToPreviousUserStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _onPageChanged(int index) {
    _messageController.clear();
    _messageFocusNode.unfocus();

    setState(() {
      _currentIndex = index;
      _isLiked = false;
    });
    _progressController.reset();
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentStory = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          if (!_messageFocusNode.hasFocus) {
            _progressController.stop();
          }
        },
        onTapUp: (details) {
          if (_messageFocusNode.hasFocus) {
            _messageFocusNode.unfocus();
            return;
          }
          _progressController.forward();
          if (details.globalPosition.dx < screenWidth * 0.38) {
            // Left side tapped -> previous user story
            _goToPreviousUserStory();
          } else {
            // Right side tapped -> next user story
            _goToNextUserStory();
          }
        },
        onTapCancel: () {
          if (!_messageFocusNode.hasFocus) {
            _progressController.forward();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Horizontal PageView enabling horizontal sliding between user stories
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.stories.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      story.mediaUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                      ),
                    ),
                    // Ambient gradient overlays
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 160,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 220,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top Progress Bar & Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Single continuous progress bar for the CURRENT user's story
                    Container(
                      height: 3.0,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Author Header Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundImage: NetworkImage(currentStory.authorAvatar),
                          backgroundColor: Colors.white24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStory.authorName,
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Story • ${_currentIndex + 1} of ${widget.stories.length}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Caption & Interactive Reply Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: bottomInset > 0 ? bottomInset + 12 : 24,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent taps inside bottom bar from triggering story slide
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentStory.caption.isNotEmpty && bottomInset == 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            currentStory.caption,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                const Shadow(color: Colors.black87, blurRadius: 10),
                              ],
                            ),
                          ),
                        ),

                      // Floating Quick Reactions Bar (when typing)
                      if (_messageFocusNode.hasFocus)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final emoji in const ['🔥', '❤️', '😂', '😮', '😢', '👏'])
                                TactileBounce(
                                  onTap: () => _sendMessage(currentStory.authorName, emoji),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.25),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Message Input Field + Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: _messageFocusNode.hasFocus
                                          ? Colors.white.withOpacity(0.55)
                                          : Colors.white.withOpacity(0.22),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _messageFocusNode,
                                    cursorColor: Colors.white,
                                    cursorWidth: 1.8,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _sendMessage(currentStory.authorName),
                                    decoration: InputDecoration(
                                      hintText: 'Send message to ${currentStory.authorName}...',
                                      hintStyle: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.60),
                                        fontSize: 13.5,
                                      ),
                                      isDense: true,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // If typing or focused, show Send Button
                          if (_messageFocusNode.hasFocus) ...[
                            TactileBounce(
                              onTap: _messageController.text.trim().isNotEmpty
                                  ? () => _sendMessage(currentStory.authorName)
                                  : null,
                              child: _messageController.text.trim().isNotEmpty
                                  ? Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFE2C55), Color(0xFFFF5E62)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFE2C55).withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.45),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.22),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.arrow_upward_rounded,
                                            color: Colors.white.withOpacity(0.35),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Like reaction button
                          TactileBounce(
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _isLiked
                                        ? AppColors.primary.withOpacity(0.20)
                                        : Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isLiked
                                          ? AppColors.primary
                                          : Colors.white.withOpacity(0.22),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _isLiked ? AppColors.primary : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // If NOT focused, show Share button
                          if (!_messageFocusNode.hasFocus) ...[
                            const SizedBox(width: 8),
                            TactileBounce(
                              onTap: () {
                                NativeShareService.sharePost(
                                  postId: currentStory.id,
                                  imageUrl: currentStory.mediaUrl,
                                  caption: currentStory.caption,
                                  authorUsername: currentStory.authorName,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.22),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
