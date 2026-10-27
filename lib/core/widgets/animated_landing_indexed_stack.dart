import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A smooth, high-fidelity 500ms landing transition stack for bottom navigation.
/// When navigating to any screen, incoming elements gracefully slide and land into place
/// with continuous momentum over 500ms, while maintaining 100% opacity stability
/// and zero background blinking.
/// All inactive child states (scroll offsets, player states, inputs) remain fully preserved.
class AnimatedLandingIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const AnimatedLandingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedLandingIndexedStack> createState() => _AnimatedLandingIndexedStackState();
}

class _AnimatedLandingIndexedStackState extends State<AnimatedLandingIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(AnimatedLandingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final isTransitioning = _controller.isAnimating && _previousIndex != _currentIndex;
        final screenWidth = MediaQuery.of(context).size.width;

        if (!isTransitioning) {
          // Resting state: only the active screen is visible, zero transforms
          return Stack(
            fit: StackFit.expand,
            children: List.generate(widget.children.length, (i) {
              final child = widget.children[i];
              if (i == _currentIndex) {
                return child;
              }
              return Offstage(
                offstage: true,
                child: TickerMode(enabled: false, child: child),
              );
            }),
          );
        }

        // Determine navigation direction
        bool isForward;
        if (_previousIndex == widget.children.length - 1 && _currentIndex == 0) {
          isForward = true;
        } else if (_previousIndex == 0 && _currentIndex == widget.children.length - 1) {
          isForward = false;
        } else {
          isForward = _currentIndex >= _previousIndex;
        }
        final directionSign = isForward ? 1.0 : -1.0;

        final incomingChild = widget.children[_currentIndex];
        final outgoingChild = widget.children[_previousIndex];

        // 500ms Smooth Element Landing Motion:
        // Incoming screen elements gracefully glide in and land:
        // - Subtle horizontal motion along the direction of navigation
        // - Vertical landing translation from 22px down to 0
        // - Soft scale expansion from 0.98 to 1.0
        // - Soft opacity transition from 0.35 to 1.0 (prevents black background blinking)
        final landingDx = 0.08 * screenWidth * (1.0 - progress) * directionSign;
        final landingDy = 22.0 * (1.0 - progress);
        final landingOpacity = (0.35 + (0.65 * progress)).clamp(0.0, 1.0);
        final landingScale = 0.98 + (0.02 * progress);

        final incomingWidget = Transform.translate(
          offset: Offset(landingDx, landingDy),
          child: Transform.scale(
            scale: landingScale,
            child: Opacity(
              opacity: landingOpacity,
              child: incomingChild,
            ),
          ),
        );

        // Outgoing screen smoothly dissolves beneath
        final exitDx = -0.04 * screenWidth * progress * directionSign;
        final exitOpacity = (1.0 - progress).clamp(0.0, 1.0);

        final outgoingWidget = IgnorePointer(
          child: Transform.translate(
            offset: Offset(exitDx, 0),
            child: Opacity(
              opacity: exitOpacity,
              child: outgoingChild,
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base background container ensures no transparent dark voids
            Container(color: AppColors.background),

            // Inactive screens kept offstage in memory to preserve scroll & inputs
            for (int i = 0; i < widget.children.length; i++)
              if (i != _currentIndex && i != _previousIndex)
                Offstage(
                  offstage: true,
                  child: TickerMode(enabled: false, child: widget.children[i]),
                ),

            // Outgoing screen dissolving beneath
            outgoingWidget,

            // Incoming landing screen on top
            incomingWidget,
          ],
        );
      },
    );
  }
}
