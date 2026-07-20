part of 'edit_worker_bloc.dart';

class EditWorkerState extends Equatable {
  const EditWorkerState({
    this.status = RequestStatus.initial,
    this.failure,
    this.updatedWorker,
  });

  final RequestStatus status;
  final Failure? failure;
  final WorkerEntity? updatedWorker;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  EditWorkerState copyWith({
    RequestStatus? status,
    Failure? failure,
    WorkerEntity? updatedWorker,
    bool clearFailure = false,
  }) {
    return EditWorkerState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      updatedWorker: updatedWorker ?? this.updatedWorker,
    );
  }

  @override
  List<Object?> get props => [status, failure, updatedWorker];
}
