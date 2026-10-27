import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/comment_model.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';

class CommentBottomSheet extends StatefulWidget {
  final PostEntity post;
  final Function(String text) onAddComment;

  const CommentBottomSheet({
    super.key,
    required this.post,
    required this.onAddComment,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CommentEntity> _localComments = [];
  StreamSubscription<List<CommentModel>>? _subscription;

  @override
  void initState() {
    super.initState();
    _localComments.addAll(widget.post.comments);

    try {
      final stream = di.sl<FeedRemoteDataSource>().streamComments(widget.post.id);
      _subscription = stream.listen((remoteList) {
        if (!mounted) return;
        setState(() {
          final Map<String, CommentEntity> map = {};
          for (final c in remoteList) {
            map[c.id] = c;
          }
          for (final c in _localComments) {
            if (!map.containsKey(c.id)) {
              final exists = map.values.any((sc) =>
                  sc.text == c.text && sc.authorName == c.authorName);
              if (!exists) {
                map[c.id] = c;
              }
            }
          }
          _localComments.clear();
          _localComments.addAll(map.values);
          _localComments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    final currentUserName = authState is Authenticated ? authState.user.fullName : 'Alex Johnson';
    final currentUserAvatar = authState is Authenticated
        ? authState.user.avatarUrl
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80';

    final optimisticComment = CommentEntity(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      authorName: currentUserName,
      authorAvatar: currentUserAvatar,
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _localComments.add(optimisticComment);
    });

    widget.onAddComment(text);
    _commentController.clear();
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${_localComments.length})',
                  style: AppTypography.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _localComments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No comments yet.', style: AppTypography.titleLarge.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text('Start the conversation!', style: AppTypography.bodySmall),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _localComments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _localComments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(comment.authorAvatar),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment.authorName, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat.jm().format(comment.timestamp),
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: InputDecoration(
                      hintText: 'Add a thoughtful comment...',
                      hintStyle: AppTypography.bodySmall,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TactileBounce(
                  onTap: _submitComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
