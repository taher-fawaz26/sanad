part of 'worker_activity_cubit.dart';

class WorkerActivityState extends Equatable {
  const WorkerActivityState({
    this.status = RequestStatus.initial,
    this.items = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<ActivityLogEntry> items;
  final Failure? failure;

  bool get isLoadingFirstLoad =>
      status == RequestStatus.loading && items.isEmpty;

  bool get isEmpty => status == RequestStatus.success && items.isEmpty;

  WorkerActivityState copyWith({
    RequestStatus? status,
    List<ActivityLogEntry>? items,
    Failure? failure,
    bool clearFailure = false,
  }) => WorkerActivityState(
    status: status ?? this.status,
    items: items ?? this.items,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, items, failure];
}
