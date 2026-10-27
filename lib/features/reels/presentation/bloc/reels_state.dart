import 'package:equatable/equatable.dart';
import '../../domain/entities/reel_entity.dart';

enum ReelsStatus { initial, loading, loaded, error }

class ReelsState extends Equatable {
  final ReelsStatus status;
  final List<ReelEntity> reels;
  final int activeIndex;
  final String? errorMessage;
  final String? toastMessage;

  const ReelsState({
    required this.status,
    required this.reels,
    this.activeIndex = 0,
    this.errorMessage,
    this.toastMessage,
  });

  factory ReelsState.initial() {
    return const ReelsState(
      status: ReelsStatus.initial,
      reels: [],
      activeIndex: 0,
    );
  }

  ReelsState copyWith({
    ReelsStatus? status,
    List<ReelEntity>? reels,
    int? activeIndex,
    String? errorMessage,
    String? toastMessage,
  }) {
    return ReelsState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      activeIndex: activeIndex ?? this.activeIndex,
      errorMessage: errorMessage,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [status, reels, activeIndex, errorMessage, toastMessage];
}
