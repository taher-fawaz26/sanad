part of 'add_service_bloc.dart';

class AddServiceState extends Equatable {
  const AddServiceState({
    this.status = RequestStatus.initial,
    this.createdService,
    this.failure,
  });

  final RequestStatus status;
  final ProviderServiceEntity? createdService;
  final Failure? failure;

  bool get isSubmitting => status == RequestStatus.loading;

  AddServiceState copyWith({
    RequestStatus? status,
    ProviderServiceEntity? createdService,
    Failure? failure,
    bool clearFailure = false,
  }) => AddServiceState(
    status: status ?? this.status,
    createdService: createdService ?? this.createdService,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, createdService, failure];
}
