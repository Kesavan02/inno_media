import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reel_entity.dart';
import '../../domain/usecases/reels_usecases.dart';
import 'reels_event.dart';
import 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final GetReelsUseCase getReelsUseCase;
  final ToggleLikeReelUseCase toggleLikeReelUseCase;
  final AddReelCommentUseCase addReelCommentUseCase;
  final ShareReelUseCase shareReelUseCase;

  ReelsBloc({
    required this.getReelsUseCase,
    required this.toggleLikeReelUseCase,
    required this.addReelCommentUseCase,
    required this.shareReelUseCase,
  }) : super(ReelsState.initial()) {
    on<LoadReelsEvent>(_onLoadReels);
    on<ChangeActiveReelIndexEvent>(_onChangeActiveIndex);
    on<ToggleLikeReelEvent>(_onToggleLikeReel);
    on<AddReelCommentEvent>(_onAddReelComment);
    on<ShareReelEvent>(_onShareReel);
  }

  Future<void> _onLoadReels(
    LoadReelsEvent event,
    Emitter<ReelsState> emit,
  ) async {
    emit(state.copyWith(status: ReelsStatus.loading));
    try {
      final reels = await getReelsUseCase();
      emit(state.copyWith(
        status: ReelsStatus.loaded,
        reels: reels,
        activeIndex: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReelsStatus.error,
        errorMessage: 'Failed to load reels: ${e.toString()}',
      ));
    }
  }

  void _onChangeActiveIndex(
    ChangeActiveReelIndexEvent event,
    Emitter<ReelsState> emit,
  ) {
    emit(state.copyWith(activeIndex: event.index));
  }

  Future<void> _onToggleLikeReel(
    ToggleLikeReelEvent event,
    Emitter<ReelsState> emit,
  ) async {
    final originalReels = state.reels;
    final index = originalReels.indexWhere((r) => r.id == event.reelId);
    if (index == -1) return;

    final target = originalReels[index];
    final optimisticLiked = !target.isLiked;
    final optimisticCount = optimisticLiked ? target.likesCount + 1 : (target.likesCount - 1).clamp(0, 999999);

    final updated = target.copyWith(
      isLiked: optimisticLiked,
      likesCount: optimisticCount,
    );

    final optimisticList = List<ReelEntity>.from(originalReels);
    optimisticList[index] = updated;
    emit(state.copyWith(reels: optimisticList, toastMessage: null));

    try {
      final serverReel = await toggleLikeReelUseCase(event.reelId);
      final finalReels = List<ReelEntity>.from(state.reels);
      final finalIndex = finalReels.indexWhere((r) => r.id == event.reelId);
      if (finalIndex != -1) {
        finalReels[finalIndex] = serverReel;
        emit(state.copyWith(reels: finalReels));
      }
    } on RateLimitFailure catch (r) {
      // Rollback on rate limit
      emit(state.copyWith(reels: originalReels, toastMessage: r.message));
    } catch (e) {
      emit(state.copyWith(reels: originalReels, toastMessage: 'Failed to update like'));
    }
  }

  Future<void> _onAddReelComment(
    AddReelCommentEvent event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final updatedReel = await addReelCommentUseCase(
        reelId: event.reelId,
        authorName: event.authorName,
        authorAvatar: event.authorAvatar,
        text: event.text.trim(),
      );

      final updatedReels = state.reels.map((r) {
        return r.id == event.reelId ? updatedReel : r;
      }).toList();

      emit(state.copyWith(reels: updatedReels, toastMessage: 'Comment added!'));
    } on RateLimitFailure catch (r) {
      emit(state.copyWith(toastMessage: r.message));
    } catch (e) {
      emit(state.copyWith(toastMessage: 'Could not post comment'));
    }
  }

  Future<void> _onShareReel(
    ShareReelEvent event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final updatedReel = await shareReelUseCase(event.reelId);
      final updatedReels = state.reels.map((r) {
        return r.id == event.reelId ? updatedReel : r;
      }).toList();

      emit(state.copyWith(reels: updatedReels));
    } catch (_) {
      // Ignore share increment error silently
    }
  }
}
