part of 'add_worker_bloc.dart';

class AddWorkerState extends Equatable {
  const AddWorkerState({this.status = RequestStatus.initial, this.failure});

  final RequestStatus status;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;

  AddWorkerState copyWith({
    RequestStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AddWorkerState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, failure];
}
