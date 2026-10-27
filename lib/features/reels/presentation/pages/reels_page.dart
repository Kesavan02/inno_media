import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/app_navigation_scope.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/services/native_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/reels_bloc.dart';
import '../bloc/reels_event.dart';
import '../bloc/reels_state.dart';
import '../widgets/reel_comment_bottom_sheet.dart';
import '../widgets/reel_video_player_item.dart';

class ReelsPage extends StatefulWidget {
  final bool isTabActive;

  const ReelsPage({
    super.key,
    this.isTabActive = true,
  });

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with RouteAware, WidgetsBindingObserver {
  late final PageController _pageController;
  bool _isRouteCurrent = true;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      appRouteObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Another full screen route was pushed on top of the shell
    if (mounted) setState(() => _isRouteCurrent = false);
  }

  @override
  void didPopNext() {
    // Returned to this screen from a pushed route
    if (mounted) setState(() => _isRouteCurrent = true);
  }

  @override
  void didPop() {
    if (mounted) setState(() => _isRouteCurrent = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isResumed = state == AppLifecycleState.resumed;
    if (_isAppInForeground != isResumed && mounted) {
      setState(() => _isAppInForeground = isResumed);
    }
  }

  bool get _isWatching => widget.isTabActive && _isRouteCurrent && _isAppInForeground;

  void _openComments(BuildContext context, reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReelCommentBottomSheet(
        reel: reel,
        onAddComment: (text) {
          final authState = context.read<AuthBloc>().state;
          final currentUserName = authState is Authenticated ? authState.user.fullName : 'Alex Johnson';
          final currentUserAvatar = authState is Authenticated
              ? authState.user.avatarUrl
              : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80';

          context.read<ReelsBloc>().add(
            AddReelCommentEvent(
              reelId: reel.id,
              text: text,
              authorName: currentUserName,
              authorAvatar: currentUserAvatar,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ReelsBloc, ReelsState>(
        listener: (context, state) {
          if (state.toastMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.toastMessage!, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                backgroundColor: AppColors.surfaceElevated,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ReelsStatus.loading && state.reels.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == ReelsStatus.error && state.reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: AppColors.error, size: 52),
                  const SizedBox(height: 12),
                  Text('Failed to load reels', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<ReelsBloc>().add(LoadReelsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Vertical PageView of local video reels
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: state.reels.length,
                onPageChanged: (index) {
                  context.read<ReelsBloc>().add(ChangeActiveReelIndexEvent(index));
                },
                itemBuilder: (context, index) {
                  final reel = state.reels[index];
                  final isActive = _isWatching && (index == state.activeIndex);

                  return ReelVideoPlayerItem(
                    key: ValueKey(reel.id),
                    reel: reel,
                    isActive: isActive,
                    onToggleLike: () {
                      context.read<ReelsBloc>().add(ToggleLikeReelEvent(reel.id));
                    },
                    onOpenComments: () => _openComments(context, reel),
                    onShare: () {
                      context.read<ReelsBloc>().add(ShareReelEvent(reel.id));
                      NativeShareService.shareReel(
                        reelId: reel.id,
                        videoAssetPath: reel.videoAssetPath,
                        caption: reel.caption,
                        authorUsername: reel.authorUsername,
                      );
                    },

                  );
                },
              ),

              // Top Bar overlay with Title and Camera action
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(builder: (context) {
                        final nav = AppNavigationScope.of(context);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (nav != null && nav.canBacktrack) ...[
                              GestureDetector(
                                onTap: () => nav.backtrack(),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 0.8),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                            Text(
                              'Reels',
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 24,
                                color: Colors.white,
                                shadows: [const Shadow(color: Colors.black54, blurRadius: 10)],
                              ),
                            ),
                          ],
                        );
                      }),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
