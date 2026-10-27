import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/app_navigation_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_tray.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedBloc>().add(LoadMorePostsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = AppNavigationScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: nav != null && nav.canBacktrack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => nav.backtrack(),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('InnoMedia', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<FeedBloc, FeedState>(
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
          if (state.status == FeedStatus.loading && state.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == FeedStatus.error && state.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load feed', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? '', style: AppTypography.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FeedBloc>().add(LoadFeedInitialEvent()),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceElevated,
            onRefresh: () async {
              context.read<FeedBloc>().add(RefreshFeedEvent());
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: 1 + state.posts.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // First item is Stories Tray
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: StoriesTray(stories: state.stories),
                  );
                }

                // Loading more indicator at bottom
                if (index == state.posts.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                }

                final postIndex = index - 1;
                final post = state.posts[postIndex];

                return PostCard(
                  post: post,
                  onToggleLike: () {
                    context.read<FeedBloc>().add(ToggleLikeEvent(post.id));
                  },
                  onToggleBookmark: () {
                    context.read<FeedBloc>().add(ToggleBookmarkEvent(post.id));
                  },
                  onAddComment: (text) {
                    final authState = context.read<AuthBloc>().state;
                    final currentUserName = authState is Authenticated ? authState.user.fullName : 'Alex Johnson';
                    final currentUserAvatar = authState is Authenticated
                        ? authState.user.avatarUrl
                        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80';

                    context.read<FeedBloc>().add(
                      AddCommentEvent(
                        postId: post.id,
                        text: text,
                        authorName: currentUserName,
                        authorAvatar: currentUserAvatar,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
