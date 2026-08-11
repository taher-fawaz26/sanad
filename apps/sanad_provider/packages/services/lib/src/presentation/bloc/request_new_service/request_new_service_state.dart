part of 'request_new_service_bloc.dart';

class RequestNewServiceState extends Equatable {
  const RequestNewServiceState({
    this.status = RequestStatus.initial,
    this.createdRequest,
    this.failure,
  });

  final RequestStatus status;
  final ServiceRequestEntity? createdRequest;
  final Failure? failure;

  bool get isSubmitting => status == RequestStatus.loading;

  RequestNewServiceState copyWith({
    RequestStatus? status,
    ServiceRequestEntity? createdRequest,
    Failure? failure,
    bool clearFailure = false,
  }) => RequestNewServiceState(
    status: status ?? this.status,
    createdRequest: createdRequest ?? this.createdRequest,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, createdRequest, failure];
}
