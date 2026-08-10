part of 'service_action_bloc.dart';

class ServiceActionState extends Equatable {
  const ServiceActionState({
    this.status = RequestStatus.initial,
    this.processingId,
    this.updatedService,
    this.deletedServiceId,
    this.failure,
  });

  final RequestStatus status;

  /// Id of the service currently being mutated, so the page can show a
  /// per-card busy indicator.
  final String? processingId;
  final ServiceRecordEntity? updatedService;
  final String? deletedServiceId;
  final Failure? failure;

  ServiceActionState copyWith({
    RequestStatus? status,
    String? processingId,
    ServiceRecordEntity? updatedService,
    String? deletedServiceId,
    Failure? failure,
    bool clearFailure = false,
  }) => ServiceActionState(
    status: status ?? this.status,
    processingId: processingId ?? this.processingId,
    updatedService: updatedService ?? this.updatedService,
    deletedServiceId: deletedServiceId ?? this.deletedServiceId,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [
    status,
    processingId,
    updatedService,
    deletedServiceId,
    failure,
  ];
}
