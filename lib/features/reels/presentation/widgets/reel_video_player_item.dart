import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/reel_entity.dart';
import 'reel_action_sidebar.dart';

class ReelVideoPlayerItem extends StatefulWidget {
  final ReelEntity reel;
  final bool isActive;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  const ReelVideoPlayerItem({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onShare,
  });

  @override
  State<ReelVideoPlayerItem> createState() => _ReelVideoPlayerItemState();
}

class _ReelVideoPlayerItemState extends State<ReelVideoPlayerItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  late bool _isPlaying;
  bool _isMuted = false;
  bool _showPlayPauseIcon = false;
  bool _showVolumeIndicator = false;
  bool _showBurstHeart = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isActive;
    _initializePlayer();

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showBurstHeart = false);
      }
    });
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.asset(widget.reel.videoAssetPath);
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
          await _controller!.play();
          _isPlaying = true;
        } else {
          await _controller!.setVolume(0.0);
          await _controller!.pause();
          _isPlaying = false;
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (_controller != null && _isInitialized) {
        if (widget.isActive) {
          _controller!.setVolume(_isMuted ? 0.0 : 1.0);
          _controller!.play();
          setState(() => _isPlaying = true);
        } else {
          _controller!.setVolume(0.0);
          _controller!.pause();
          setState(() => _isPlaying = false);
        }
      } else {
        _isPlaying = widget.isActive;
      }
    }
  }

  @override
  void dispose() {
    _controller?.setVolume(0.0);
    _controller?.pause();
    _controller?.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized || !widget.isActive) return;

    setState(() {
      if (_isPlaying) {
        _controller!.setVolume(0.0);
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.setVolume(_isMuted ? 0.0 : 1.0);
        _controller!.play();
        _isPlaying = true;
      }
      _showPlayPauseIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showPlayPauseIcon = false);
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      _isMuted = !_isMuted;
      if (widget.isActive && _isPlaying) {
        _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      }
      _showVolumeIndicator = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showVolumeIndicator = false);
      }
    });
  }

  void _onDoubleTap() {
    setState(() => _showBurstHeart = true);
    _heartAnimController.forward(from: 0.0);
    if (!widget.reel.isLiked) {
      widget.onToggleLike();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video View
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlayPause,
          onDoubleTap: _onDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isInitialized && _controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                ),

              // Animated Play/Pause indicator
              if (_showPlayPauseIcon)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),

              // Animated double-tap Heart Burst
              if (_showBurstHeart)
                Center(
                  child: ScaleTransition(
                    scale: _heartScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.6),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 84,
                      ),
                    ),
                  ),
                ),

              // Animated Volume Indicator
              if (_showVolumeIndicator)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMuted ? 'Muted' : 'Sound On',
                          style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Gradient Vignette Overlays
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
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

        // Volume Mute / Unmute Button in Top Right
        Positioned(
          top: 14,
          right: 56,
          child: SafeArea(
            child: GestureDetector(
              onTap: _toggleMute,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Bottom Left Content: Author, Caption, Audio Track
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author Username & Follow Tag
              Row(
                children: [
                  Text(
                    reel.authorUsername,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [const Shadow(color: Colors.black87, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 1.0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Follow',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Caption
              Text(
                reel.caption,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.black87, blurRadius: 6)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Audio Track Indicator (Tap to Mute/Unmute)
              GestureDetector(
                onTap: _toggleMute,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.graphic_eq_rounded,
                      color: _isMuted ? Colors.white54 : AppColors.secondaryLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reel.musicTrack,
                        style: AppTypography.bodySmall.copyWith(
                          color: _isMuted ? Colors.white54 : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Sidebar Actions
        Positioned(
          right: 12,
          bottom: 30,
          child: ReelActionSidebar(
            reel: reel,
            onToggleLike: widget.onToggleLike,
            onOpenComments: widget.onOpenComments,
            onShare: widget.onShare,
          ),
        ),

        // Video Progress Bar at Bottom
        if (_isInitialized && _controller != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }
}
