import 'package:core/src/blocs/request_status.dart';
import 'package:core/src/domain/failures/failure.dart';
import 'package:core/src/pagination/page_meta.dart';
import 'package:equatable/equatable.dart';

/// Reusable pagination state slice. Feature BLoC states embed one instance
/// of this (alongside their own search/filter fields) instead of
/// re-declaring `status`, `page`, `totalPages`, `loadingMore`, etc.
///
/// [firstPageError] and [nextPageError] are tracked separately: a
/// first-page error replaces the (empty) list, while a next-page error
/// leaves already-loaded [items] in place so the UI can show a retry
/// affordance without losing scroll position.
class PaginationData<T> extends Equatable {
  const PaginationData({
    this.status = RequestStatus.initial,
    this.items = const [],
    this.meta = const PageMeta.empty(),
    this.loadingMore = false,
    this.firstPageError,
    this.nextPageError,
  });

  final RequestStatus status;
  final List<T> items;
  final PageMeta meta;
  final bool loadingMore;
  final Failure? firstPageError;
  final Failure? nextPageError;

  bool get isLoadingFirstPage => status == RequestStatus.loading;
  bool get hasFirstPageError => firstPageError != null;
  bool get hasNextPageError => nextPageError != null;
  bool get hasMore => meta.hasMore;
  bool get isEmpty => status == RequestStatus.success && items.isEmpty;
  int get nextPage => meta.currentPage + 1;

  PaginationData<T> copyWith({
    RequestStatus? status,
    List<T>? items,
    PageMeta? meta,
    bool? loadingMore,
    Failure? firstPageError,
    bool clearFirstPageError = false,
    Failure? nextPageError,
    bool clearNextPageError = false,
  }) => PaginationData<T>(
    status: status ?? this.status,
    items: items ?? this.items,
    meta: meta ?? this.meta,
    loadingMore: loadingMore ?? this.loadingMore,
    firstPageError: clearFirstPageError
        ? null
        : (firstPageError ?? this.firstPageError),
    nextPageError: clearNextPageError
        ? null
        : (nextPageError ?? this.nextPageError),
  );

  @override
  List<Object?> get props => [
    status,
    items,
    meta,
    loadingMore,
    firstPageError,
    nextPageError,
  ];
}
