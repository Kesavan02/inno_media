import 'package:equatable/equatable.dart';

/// Indexed pagination cursor for streaming & paginating social feed items.
class PaginationCursor extends Equatable {
  final int pageIndex;
  final int pageSize;
  final bool hasMore;
  final int totalIndexed;

  const PaginationCursor({
    required this.pageIndex,
    required this.pageSize,
    required this.hasMore,
    this.totalIndexed = 0,
  });

  factory PaginationCursor.initial({int pageSize = 10}) {
    return PaginationCursor(
      pageIndex: 0,
      pageSize: pageSize,
      hasMore: true,
      totalIndexed: 0,
    );
  }

  PaginationCursor next({required int fetchedCount, required int totalCount}) {
    final nextIndex = pageIndex + 1;
    final hasMoreItems = (nextIndex * pageSize) < totalCount;
    return PaginationCursor(
      pageIndex: nextIndex,
      pageSize: pageSize,
      hasMore: hasMoreItems,
      totalIndexed: totalCount,
    );
  }

  @override
  List<Object?> get props => [pageIndex, pageSize, hasMore, totalIndexed];
}
